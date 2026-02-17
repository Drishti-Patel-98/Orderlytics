/* --------------------------------------------------------------------------- */
/* New vs Repeat Customers                                                     */
/* --------------------------------------------------------------------------- */
/* Question: How many customers are new vs repeat each month?
             How much revenue comes from new vs repeat customers?
   Tables: Orders, Order_Payment, Customers
   Assumptions: - Only delivered orders are analyzed
*/
With Order_Level as
(
	-- Order_Payment can have multiple rows per order. Aggregated at the order level to avoid double-counting
	select
		 T1.Order_ID
		,T1.Cust_ID
		,T1.Order_Purchase_Ts
		,sum(T2.Payment_Val) as Order_Total_Val
	from Orders T1
	inner join Order_Payment T2
		on T1.Order_ID = T2.Order_ID
	where T1.Order_Sts = 'delivered'
	group by T1.Order_ID
	        ,T1.Cust_ID
			,T1.Order_Purchase_TS
),
Ord_With_Cust as
(
-- joins order with customer
	select
		 T1.Order_ID
		,T1.Cust_ID
		,T2.Cust_Unique_ID
		,T1.Order_Purchase_Ts
		,T1.Order_Total_Val
	from Order_Level T1
	inner join Customers T2
		on T1.Cust_ID = T2.Cust_ID
),
Monthly_Cust as 
(
	-- Tag order as New or Repeat
	select
		 date_trunc('month',T1.Order_Purchase_Ts) as Order_Month
		,T1.Cust_Unique_ID
		,T1.Order_Total_Val
		,case when row_number() over(partition by cust_unique_ID order by Order_Purchase_Ts) = 1
		      then 'New'
			  else 'Repeat'
	     end as Cust_Type
	from Ord_with_Cust T1
)
select 
	 Order_Month
	,Cust_Type
	,count(distinct Cust_Unique_ID) as No_of_Cust
	,sum(Order_Total_Val) as Revenue
from Monthly_Cust
group by Order_Month
        ,Cust_Type
order by Order_Month
;

/* --------------------------------------------------------------------------- */
/* Repeat Purchase Rate                                                        */
/* --------------------------------------------------------------------------- */
/* Question: What is the repeat purchase rate each month?
   Tables: Orders, Customers
   Assumptions: - Only delivered orders are analyzed
*/
with Ord_with_Cust as
(
	-- join orders with customers
	select
		 T1.Order_ID
		,T1.Cust_ID
		,T2.Cust_Unique_ID
		,T1.Order_Purchase_Ts
	from Orders T1
	left outer join Customers T2
		on T1.Cust_ID = T2.Cust_ID
	where T1.Order_Sts = 'delivered'
	  and T2.Cust_ID is not null
),
Monthly_Ords as
(
	-- Aggregate orders at the month level
	-- Tag New vs Repeat customers
	select
		 date_trunc('month',Order_Purchase_Ts) as Order_Month
		,Cust_Unique_ID
		,case when row_number() over(partition by cust_unique_ID order by Order_Purchase_Ts) = 1
		      then 'New'
			  else 'Repeat'
		 end as Cust_Type
	from Ord_with_Cust
)

select 
	 Order_Month
	,count(distinct case when Cust_Type = 'Repeat' then Cust_Unique_ID end) as No_Of_Repeat_Cust
	,count(distinct case when Cust_Type = 'New'    then Cust_Unique_ID end) as No_Of_Repeat_Cust
	,count(distinct case when Cust_Type = 'Repeat' then Cust_Unique_ID end) * 100 
   / count(distinct Cust_Unique_ID) as Monthly_Repeat_Purchase_Rate
from Monthly_Ords
group by Order_Month
;

/* --------------------------------------------------------------------------- */
/* Customers Lifetime Value                                                    */
/* --------------------------------------------------------------------------- */
/* Question: What is the total revenue the customer generated over their entire relationship wih business?
   Tables: Orders, Customers
   Assumptions: - Only delivered orders are analyzed
*/

with Ord_with_cust as
(
	-- join orders with customer
	select
		 Order_ID
		,T1.Cust_ID
		,Cust_Unique_ID
		,Order_Purchase_Ts
	from Orders T1
	inner join Customers T2
		on T1.Cust_ID = T2.Cust_ID
	where T1.Order_Sts = 'delivered'
)
select
		 Cust_Unique_ID
		,sum(payment_val) as Total_Revenue
		,min(Order_Purchase_Ts) as First_Ord_Ts
		,max(Order_Purchase_Ts) as Last_Ord_Ts
	from Ord_with_cust T1
	inner join Order_Payment T2
		on T1.Order_ID = T2.Order_ID
	group by cust_unique_id
;

