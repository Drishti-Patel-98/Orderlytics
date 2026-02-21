## Background:

Olist is an e-commerce company in Brazil that connects multiple small businesses through a single channel. Those merchants can sell their products through Olist stores and ship them directly to customers. Between 2016 and 2018, Olist experienced rapid growth, generating over 100000 orders. However, leadership lacked clear visibility into revenue drivers, customer retention, product performance, delivery performance, and their impact on customer satisfaction.

To support data-driven decision-making, a SQL analysis was conducted to uncover operational inefficiencies, revenue concentration risks, payment, and behavioral patterns affecting long-term growth.

## Project Goal:

The objective of this project is to analyze business performance, measure customer retention, evaluate product and revenue concentration, assess payment risks, assess delivery efficiency, and examine how operational factors affect customer satisfaction.

The goal is to analyze real-world data using SQL and demonstrate a strong understanding of:

- Data modeling
- CTE structuring
- Window functions
- Aggregations
- Business metrics design

## Data Source:

This analysis is based on a public Brazilian e-commerce dataset provided by Olist, containing ~100000 orders from 2016-2018. The dataset includes transactions (Orders), customers, products, payments, sellers, and review data, allowing end-to-end analysis of the e-commerce lifecycle.

## Data Modeling:

Snowflake data model is designed to support analytical queries efficiently, where Orders is the central fact table connected to customers, products, sellers, payment, and reviews.

### Entity Relationship Diagram:
![Data model](Database%20Creation/ERD.png)

### Table Overview:

|     |     |     |
| --- | --- | --- |
| Table | Purpose | Key Relationships |
| Geolocation | Dimension table with geographic information | The geolocation table contains multiple rows for the same Zip code with different latitude and longitude values. Due to the non-unique behavior, geolocation is treated as reference data, and no physical foreign key constraints are enforced. |
| Prod_Catg_Nm_Eng | Reference table storing English transactions of product categories | This table serves as a reference for products. A physical foreign key constraint to the Products is intentionally not enforced, as some product categories do not have a corresponding English translation. |
| Products | Dimension table containing product attributes | Prod_ID 🡪 Order_Item.Prod_ID |
| Customers | Dimension table with customer-specific data | Cust_ID 🡪 Orders.Cust_ID |
| Seller | Dimension table with seller details and location data | Seller_ID 🡪 Order_Item.Seller_ID |
| Orders | Fact table containing order details | Order_ID 🡪 Order_Item.Order_ID<br><br>Order_ID 🡪 Order_Payment.Order_ID<br><br>Order_ID 🡪 Order_Review.Order_ID<br><br>Foreign Key: Cust_ID 🡪 Customers.Cust_ID |
| Order_Item | Bridge table connecting Orders to product and sellers at the item level | Foreign Key: Order_ID 🡪 Orders.Order_ID, Prod_ID 🡪 Products.Prod_ID, Seller_ID 🡪 Seller.Seller_  <br>ID |
| Order_Payment | Table storing payment information per order | Foreign Key: Order_ID 🡪 Orders.Order_ID |
| Order_Review | Contains customer review data linked to Orders | Foreign Key: Order_ID 🡪 Orders.Order_ID |

## Assumptions:

- Revenue is calculated using Payment_Val from Order_Payment table. Freight charges are included where reflected in the payment value.
- Customers are uniquely identified using Unique_Cust_Id.
- Only delivered orders are analyzed.
- An order is considered on time when Order_Dlvrd_Cust_Ts <= Order_Estmt_Dlvry_Ts
- Customer lifetime revenue is calculated as historical cumulative revenue per customer. This is not predictive CLV.
- Orders are classified as installment-based in Payment_Installmnt_No >1

## Metrics and Analysis Approach:

### 1.  Revenue and Growth:

|     |     |     |
| --- | --- | --- |
| Metric | SQL approach | Business Insight |
| Total monthly revenue | SUM of Payment_Val grouped by Year/Month | Understand overall revenue trends and seasonality |
| Average Order Value (AOV) | SUM(Payment_Val) / Count (distinct Order_ID) | Identifying order size over time |
| Month-over-Month Revenue Growth | (Current month revenue – Previous month revenue) / Previous month revenue using LAG () | Measure growth rate |

### 2.  Customer Behavior:

|     |     |     |
| --- | --- | --- |
| Metric | SQL approach | Business Insight |
| New vs Repeat Customers | ROW_NUMBER () OVER (PARTITION BY cust_unique_ID ORDER BY Order_Purchase_Ts) = 1 to tag first order as ‘New’ and others as ‘Repeat’ | Assess customer retention |
| Repeat Purchase Rate | COUNT (distinct repeat customers) / COUNT (distinct all customers) | Evaluate loyalty and recurring revenue potential |
| Customer Lifetime Value (CLV) | SUM (Payment_Val) per customer | Determine the long-term revenue of each customer |

### 3.  Product Performance:

|     |     |     |
| --- | --- | --- |
| Metric | SQL approach | Business Insight |
| Revenue per Product Category | SUM (Price + Freight_Val) by product category | Identify top-selling product categories |
| Revenue Concentration (Pareto Analysis) | Rank product categories by revenue, top 10% contribution using ROW_NUMBER and count (Prod_ID) over () | Identify the Products Categories driving the majority of revenue |

### 4.  Operational metrics:

|     |     |     |
| --- | --- | --- |
| Metric | SQL approach | Business Insight |
| Order fulfillment Time | Order_Dlvrd_Cust_Ts – Order_Purchase_Ts | Measure the total time taken to deliver an order after purchase |
| On-time Delivery Rate | Count (Orders delivered on time) / Count (Total Orders) | Order fulfilment efficiency |
| Late Delivery Rate | Count (Orders delivered late) / Count (Total Orders) | Identifying operational bottleneck |

### 5.  Payment and Risk:

|     |     |     |
| --- | --- | --- |
| Metric | SQL approach | Business Insight |
| Payment Method Breakdown | SUM of Revenue per payment type | Understand revenue distribution across payment methods |
| Installment Analysis | Tag Order as single payment vs installments, and calculate the average order value | Identify whether higher order value rely on installment payments |

### 6.  Customer Satisfaction:

|     |     |     |
| --- | --- | --- |
| Metric | SQL approach | Business Insight |
| Revenue Vs Review Score | CORR (Review_Score, Revenue) | Determine if higher revenue orders lead to better reviews |
| Late Delivery Impact | Compare the average review score for ‘On-Time’ Vs ‘Late’ Orders | Assess operational impact on customer satisfaction |

## Key Insights:

- Revenue increased from late 2016 to 2017 because the number of orders grew, not because customers were spending more per order. In 2018, revenue leveled off at around 1M per month, suggesting that growth may be slowing down. Since revenue has been driven mostly by higher order volume rather than higher average order value (AOV), the company should focus on improving customer retention and increasing AOV, while also exploring new customer acquisition channels to support future growth.
- Product-level revenue analysis shows that top 10% of products contributes 59.15% of total revenue. Product categories like health_beauty, watches_gifts, bed_bath_table, sports_leisure, computers_accessories are driving high revenue. The result highlights prioritizing high perfoming product categories while optimizing low performing categories to reduce revenue risk.
- Customer behaviour analysis shows that approximately 95% of revenue is generated from new customers, while repeat customers contribution is very minimal (~3%). This indicates revenue growth is customer acquisition-driven, creating depency risk on continuous customer acqusition. To improve long-term profitability, the company should focus on customer retention strategies.
- Payment behaviour analysis shows that the most revenue processed by credit cards (~78%), while customers opt for installments for high value products (AOV $197.23). For low contributing methods like debit card or vouchers, the comapny may choose to optimize these channels or running targted promotions to improve adoption.
- Analysis of revenue vs review ratings shows that most orders (4–5 stars) have mid-range average order values ($154–$156), while low-rated orders (1–2 stars) have higher AOV ($170–$193). However, the overall correlation between revenue and reviews is very weak (-0.042), indicating that spending more does not necessarily lead to higher or lower customer satisfaction. This suggests that premium products may require extra attention on quality and post-purchase support, while mid-range products drive both volume and positive reviews.
-  The average delivery time of delivered orders is 12.5 days. Approximately 91.89% orders delivered on or before time, while 8.11% are late. This shows an efficient operations. Also, analysis of delivery performance shows that on-time orders receive an average review of 4.29, while late orders average only 2.57. This highlights that timely delivery has a strong impact on customer satisfaction and improving late deliveries can meaningfully boost overall review scores.

## Tools Used:

- SQL: For data extraction and loading
- Database Management System: PostgreSQL to host and manage the dataset
- Programming Language: SQL for data processing and scripting

## Note:

For this SQL-focused phase, I intentionally worked with the raw dataset to reflect real-world analytical conditions. Instead of globally cleaning the data, I handled quality issues within each query through filters, joining strategies, and documented assumptions. In the future phase, I plan to implement formal data modeling and data quality checks using dbt.
