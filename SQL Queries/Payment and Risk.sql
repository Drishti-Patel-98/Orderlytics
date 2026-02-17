/* --------------------------------------------------------------------------- */
/* Payment Method Breakdown                                                    */
/* --------------------------------------------------------------------------- */
/* Question: What payment methods are used and how do they impact revenue?
   Tables: Orders, Order_Payment
   Assumptions: - Only delivered orders are analyzed.
                - Revenue = SUM(Payment_Val)
   Note: No of Split payments = No of payments - No of orders
*/

select 
	 Payment_Type
	,count(distinct T1.Order_ID) as Total_Orders
	,count(T2.Payment_Seq_No) as Total_Payments --includes split payments
	,sum(T2.Payment_Val) as Total_Revenue
	,round(sum(T2.Payment_Val) / count(distinct T1.Order_ID)
	       ,2)as Avg_Order_Val
	,round(sum(T2.Payment_Val)*100 / sum(sum(T2.Payment_Val)) over()
	       ,2) as Pct_Of_Total_Revenue
from Orders T1
inner join Order_Payment T2
	on T1.Order_ID = T2.Order_ID
where T1.Order_Sts = 'delivered'
group by Payment_Type
order by Total_Revenue
;

/* --------------------------------------------------------------------------- */
/* Installment Analysis                                                        */
/* --------------------------------------------------------------------------- */
/* Question: Do customers use installments, and how do they impact revenue?
   Tables: Orders, Order_Payment
   Assumptions: - Only delivered orders are analyzed.
                - Revenue = SUM(Payment_Val)
				- MAX(Payment_Installmnt_no) is used to get installments vs a single payment
*/

With Ord_Pymt as 
(
	-- Get the number of installments per order
	select
		 T1.Order_ID
		,sum(T2.Payment_Val) as Order_Total
		,max(T2.Payment_Installmnt_no) as No_Of_Installments
	from Orders T1
	inner join Order_Payment T2
			on T1.Order_ID = T2.Order_ID
	where T1.Order_Sts = 'delivered'
	group by T1.Order_ID
),
Tagged_Orders as
(
	-- Tag order as single payment or installment
	select
		 Order_ID
		,Order_Total
		,case when No_Of_Installments > 1 then 'installment' else 'single-payment' end as Payment_Type
	from Ord_Pymt
)
select
	 Payment_Type
	,count(distinct Order_ID) as No_Of_Orders
	,sum(Order_Total) as Total_Revenue
	,round(sum(Order_Total)*100 / sum(sum(Order_Total)) over()
	       ,2) as Pct_Of_Total_Revenue
	,round(sum(Order_Total) / count(distinct Order_ID)
	       ,2) as Avg_Order_Value
from Tagged_Orders
group by Payment_Type
;
