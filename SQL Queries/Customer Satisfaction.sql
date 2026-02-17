/* --------------------------------------------------------------------------- */
/* Reviews vs Revenue                                                          */
/* --------------------------------------------------------------------------- */
/* Question: Do higher review scores correlate to higher revenue?
   Tables: Orders, Order_Payment, Order_Review
   Assumptions: - Only delivered orders are analyzed.
                - Revenue = SUM(Payment_Val)
				- Review score ranges from 1 to 5
*/

with Order_Revenue as
(
	-- join orders with order payment
	select
		 T1.Order_ID
		,sum(T2.Payment_Val) as Revenue
	from Orders T1
	inner join Order_Payment T2
		on T1.Order_ID = T2.Order_ID
	where T1.Order_Sts = 'delivered'
	group by T1.Order_ID
),
Order_Review as
(
	-- Get review score for orders
	select 
		 T3.Order_ID
		,Review_Score
		,T4.Revenue
	from Order_Review T3
	inner join Order_Revenue T4
		on T3.Order_ID = T4.Order_ID
)
select corr(Review_Score::numeric,Revenue) as correlation -- Positive: Higher review score tends to come with higher revenue. 
                                                          -- Zero: No relation 
														  -- Negative: Higher review score tends to come with low revenue
from Order_Review
;

-- To analyze revenue by review score
with Order_Revenue as
(
	-- join orders with order payment
	select
		 T1.Order_ID
		,sum(T2.Payment_Val) as Revenue
	from Orders T1
	inner join Order_Payment T2
		on T1.Order_ID = T2.Order_ID
	where T1.Order_Sts = 'delivered'
	group by T1.Order_ID
),
Order_Review as
(
	-- Get review score for orders
	select 
		 T3.Order_ID
		,Review_Score
		,T4.Revenue
	from Order_Review T3
	inner join Order_Revenue T4
		on T3.Order_ID = T4.Order_ID
)
select 
	 Review_Score
	,count(Order_ID) as no_Of_Orders
	,Avg(Revenue) as Avg_Revenue
from Order_Review
group by Review_Score
;


/* --------------------------------------------------------------------------- */
/* Impact of Late Delivery on Reviews                                          */
/* --------------------------------------------------------------------------- */
/* Question: How does late delivery affect review scores?
   Tables: Orders, Order_Payment, Order_Review
   Assumptions: - Only delivered orders are analyzed.
                - Revenue = SUM(Payment_Val)
				- Review score ranges from 1 to 5
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
),
Reviews_with_Delivery as
(
	select
		 T1.Order_ID
		,Delivery_Tag
		,Review_Score::numeric as Review_Score
	from Tagged_Orders T1
	inner join Order_Review T2
		on T1.Order_ID = T2.Order_ID
		
)
select
	 Delivery_Tag
	,count(distinct Order_ID) as No_Of_Orders
	,round(avg(Review_Score)
	       ,2) as Avg_Review_Score
from Reviews_with_Delivery
group by Delivery_Tag
