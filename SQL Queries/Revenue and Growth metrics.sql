/* --------------------------------------------------------------------------- */
/* Monthly Revenue Performance                                                 */
/* --------------------------------------------------------------------------- */
/* Question: - What is the total monthly revenue?
             - Is revenue growth driven by increased order volume or higher average order value?
             - How fast is revenue growing month over month?
   Metrics:  - Total Revenue
             - Total Orders
			 - Average Order Value (AOV)
			 - Month-over-Month Growth %   
   Tables: Orders, Order_Payment
   Assumptions: - Only delivered orders are analyzed
                - Revenue = SUM(Payment_Val)
				- As per the data, Payment_Val = price + freight_val
*/

with Order_Level_Revenue as
(
	/* Create revenue fact table at order-level */
	/* Order_Payment can have multiple rows per order. Aggregated at the order level to avoid double-counting */
	select 
		 T1.Order_ID
		,extract(year from T1.Order_Purchase_Ts) as Order_Year
		,extract(month from T1.Order_Purchase_Ts) as Order_Month
		,sum(T2.Payment_Val) as Total_Order_Val
	from Orders T1
	inner join Order_Payment T2 -- Used inner join to exclude orders without payment
		on T1.Order_ID = T2.Order_ID
	where T1.Order_Sts = 'delivered'
	group by T1.Order_ID
		   , Order_Year
           , Order_Month
),
Monthly_Metrics as
(
	/* Aggregate metrics at the month-level */
	select 
		 Order_Year
		,Order_Month
		,sum(Total_Order_Val) as Total_Revenue
		,count(Order_ID) as Total_Orders
		,sum(Total_Order_Val) / nullif(count(Order_ID),0) as Avg_Order_Value
	from Order_Level_Revenue
	group by Order_Year
	       , Order_Month
),
Final_Result as
(
	/* Calcualte MoM Growth % */
	select
		 Order_Year
		,Order_Month
		,Total_Revenue
		,Total_Orders
		,Avg_Order_Value
		,lag(Total_Revenue) over(order by Order_Year,Order_Month) as Previous_Month_Revenue
	from Monthly_Metrics
)
select
	Order_Year
   ,Order_Month
   ,Total_Revenue
   ,Total_Orders
   ,Avg_Order_Value
   ,round(
   			(Total_Revenue - Previous_Month_Revenue)
			  / nullif(Previous_Month_Revenue,0) *100
		 ,2) as MoM_Revenue_Growth_Pct
from Final_Result
;
