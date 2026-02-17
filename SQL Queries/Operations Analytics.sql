/* --------------------------------------------------------------------------- */
/* Order Fulfillment Time                                                      */
/* --------------------------------------------------------------------------- */
/* Question: What is the average time from purchase to delivery?
   Tables: Order
   Assumptions: - Only delivered orders are analyzed.
                - Orders with NULL delivery dates excluded.
*/

select 
	round(
		avg(Order_dlvrd_cust_Ts::date - Order_Purchase_Ts::date)
		,2
		) as Avg_Delivery_Time_Days
from Orders
where Order_Sts = 'delivered'
	and Order_dlvrd_cust_Ts is not null
;

/* --------------------------------------------------------------------------- */
/* Delivery Rate                                                               */
/* --------------------------------------------------------------------------- */
/* Question: - What % of orders are delivered on or before the estimated time?
             - What % of orders are delivered late?
   Tables: Order
   Assumptions: - Only delivered orders are analyzed.
                - Orders with NULL delivery or estimated dates excluded.
*/
with Tagged_Orders as
(
	-- Tag Ontime vs Late orders
	select
		 Order_ID
		,case when Order_Dlvrd_Cust_Ts <= Order_Estmt_Dlvry_Ts 
		      then 'ontime'
			  else 'late'
		 end as Delivery_Tag
	from Orders
	where Order_Sts = 'delivered'
		and Order_dlvrd_cust_Ts is not null
		and Order_Estmt_Dlvry_Ts is not null
)
select 
	 round(count (case when Delivery_Tag = 'ontime' then 1 end) * 100.0 / count(*)
	       ,2) as On_Time_Dlvry_Pct
	,round(count (case when Delivery_Tag = 'late' then 1 end) * 100.0 / count(*)
	       ,2) as Late_Dlvry_Pct
from Tagged_Orders
;

