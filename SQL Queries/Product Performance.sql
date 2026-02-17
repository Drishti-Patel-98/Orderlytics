/* --------------------------------------------------------------------------- */
/* Top product Categories by Revenue                                           */
/* --------------------------------------------------------------------------- */
/* Question: Which product categories generate the most revenue?
   Tables: Order, Order_Item, Products, Prod_Catg_Nm_Eng
   Assumptions: - Only delivered orders are analyzed.
                - Revenue = SUM(Price + Freight_Val) at item level
*/

with Products_Eng as
(
	-- Translate product category names in English
	select 
		 T1.Prod_ID
		,T1.Prod_Catg_Nm
		,T2.Prod_Catg_Nm_Eng
	from Products T1
	left outer join Prod_Catg_Nm_Eng T2 -- Using left outer join to include products that do not have english transaltion
		on T1.Prod_Catg_Nm = T2.Prod_Catg_Nm
	where T1.Prod_Catg_Nm is not null -- Excluding products where category is not present
)

select 
	 T3.Prod_Catg_Nm
	,T3.Prod_Catg_Nm_Eng 
	,count(distinct T2.Order_ID) as Total_Orders
	,Count(T1.Order_Item_ID) as Total_Items_Sold
	,round(avg(T1.Price + T1.Freight_Val),2) as Avg_Item_Value
	,sum(T1.Price + T1.Freight_Val) as Revenue
from Order_item T1
inner join Orders T2 
	on T1.Order_ID = T2.Order_ID
inner join Products_Eng T3
	on T1.Prod_Id = T3.Prod_ID
where T2.Order_Sts = 'delivered'
group by T3.Prod_Catg_Nm
        ,T3.Prod_Catg_Nm_Eng 
order by revenue desc
--limit 10
;


/* --------------------------------------------------------------------------- */
/* Revenue Concentration (Pareto Analysis)                                     */
/* --------------------------------------------------------------------------- */
/* Question: Which % of revenue comes from the top 10% of products?
   Tables: Order, Order_Item, Products
   Assumptions: - Only delivered orders are analyzed.
                - Revenue = SUM(Price + Freight_Val) at item level
*/

with Product_Revenue as 
(
	-- Calculate revenue at order-item level
	select 
		 T1.Prod_ID
		,sum(T1.Price + T1.Freight_Val) as Revenue
	from Order_item T1
	inner join Orders T2 
		on T1.Order_ID = T2.Order_ID
	where T2.Order_Sts = 'delivered'
	group by T1.Prod_ID
),
Ranked_Products as
(
	--  Rank products by Revenue
	select 
		 Prod_ID
		,Revenue
		,ROW_NUMBER() over(Order by Revenue desc) as Revenue_Rank
		,count(Prod_ID) over() as Total_Products
		,sum(Revenue) over() as Total_Revenue
	from Product_Revenue
),
Top_10_Percent_Products as
(
	-- Get the top 10% of products
	select
		 Prod_ID
		,Revenue
		,Revenue_Rank
		,Total_Products
		,Total_Revenue
	from Ranked_Products
	where Revenue_Rank <= ceil(Total_Products * 10.0/100) -- Give top 10% of products. 
	                                                      -- If the total products are 1000, then the top 10% of products are 100
)
select
	 sum(Revenue) *100 / MAX(Total_Revenue) /* The reason for MAX() is to fetch only one value for Total_Revenue 
	                                           as all rows has the same value */
from Top_10_Percent_Products