/*-------------------------------------------------------- Geolocation --------------------------------------------------------------------*/
/* Limitation: - The geolocation table contains multiple rows for the same Zip code with different latitude and longitude values. 
               - No deduplication or standardization is applied in this SQL-focused project.
			   - The data quality handing are planned for a future modeling phase.
   Note: Due to the non-unique behavior, geolocation is treated as reference data and no physical foreign key constraints are enforced.
*/

create table Geolocation
(
	 Zip_Cd VARCHAR(5) NOT NULL -- Not enforced as a primary key due to known duplication in the source data
	,Latitude DECIMAL
	,Longitude DECIMAL
	,City VARCHAR(50)
	,State CHAR(2)
);

/*----------------------------------------------- Product Category Name Translation ------------------------------------------------------*/
/* Purpose: The Original dataset contains product category names in Portuguese. 
            This table provides a mapping from the original category name to its English equivalent.
   Note: - This table serves as a reference.
         - A physical foreign key constraint to the Products is intentionally not enforced,
		   as some product categories do not have a corresponding English translation. 
		 - Missing Translation can be handled using LEFT JOIN.
*/
create table Prod_Catg_Nm_Eng
(
	 Prod_Catg_Nm VARCHAR(50) NOT NULL
	,Prod_Catg_Nm_Eng VARCHAR(50)
	,primary key(Prod_Catg_Nm)
);

/*---------------------------------------------------------- Products --------------------------------------------------------------------*/
/* Note: - Product category names may not have a corresponding English translation.
         - When joining to the category translation table, LEFT JOINs should be used to avoid excluding valid product records.
*/

create table Products
(
	 Prod_ID VARCHAR(32) NOT NULL
	,Prod_Catg_Nm VARCHAR(50)
	,Prod_Nm_Len INTEGER
	,Prod_Desc_Len INTEGER
	,Prod_Photo_Qty INTEGER
	,Prod_Weight_Gm INTEGER
	,Prod_Len_Cm INTEGER
	,Prod_Height_Cm INTEGER
	,Prod_Width_Cm INTEGER
	,primary key(Prod_ID)
);

/*--------------------------------------------------------- Customers --------------------------------------------------------------------*/
/* Note: - Cust_ID represents the customer identifier at the order level and is used to join with the Orders table.
         - Cust_Unique_ID represents a unique individual customer across multiple orders and enables repeat purchase analysis.
		 - A single customer may have multiple Cust_ID values associated with different orders, while sharing the same Cust_Unique_ID.
		 - Cust_Zip_Cd is not enforced as a foreign key to the Geolocation table due to known non-unique zip code records in the source data.
*/

create table Customers
(
	 Cust_ID VARCHAR(32) NOT NULL
	,Cust_Unique_ID VARCHAR(32) NOT NULL
	,Cust_Zip_Cd VARCHAR(5)
	,Cust_City VARCHAR(32)
	,Cust_State CHAR(2)
	,primary key(Cust_ID)
);

/*------------------------------------------------------------ Seller --------------------------------------------------------------------*/
/* Note: Seller_Zip_Cd is not enforced as a foreign key to the Geolocation table due to known non-unique zip code records in the source data.
*/
create table Seller
(
	 Seller_ID VARCHAR(32) NOT NULL
	,Seller_Zip_Cd VARCHAR(5)
	,Seller_City VARCHAR(50)
	,Seller_State CHAR(2)
	,primary key(Seller_ID)
);

/*----------------------------------------------------------- Orders --------------------------------------------------------------------*/
create table Orders
(
	 Order_ID VARCHAR(32) NOT NULL
	,Cust_ID VARCHAR(32) NOT NULL --added constraint using ALTER TABLE
	,Order_Sts VARCHAR(20)
	,Order_Purchase_Ts TIMESTAMP
	,Order_Approved_Ts TIMESTAMP
	,Order_Dlvrd_Carrier_Ts TIMESTAMP
	,Order_Dlvrd_Cust_Ts TIMESTAMP
	,Order_Estmt_Dlvry_Ts TIMESTAMP
	,primary key(Order_ID)
);
Alter table Orders drop constraint Fk_Cust_Ord;
ALTER TABLE Orders
ADD CONSTRAINT Fk_Cust_Ord
FOREIGN KEY (Cust_ID)
REFERENCES Customers(Cust_ID);

/*-------------------------------------------------------- Order Item --------------------------------------------------------------------*/
create table Order_Item
(
	 Order_ID VARCHAR(32) NOT NULL references Orders(Order_ID)
	,Order_Item_ID INTEGER NOT NULL
	,Prod_ID VARCHAR(32) references Products(Prod_ID)
	,Seller_ID VARCHAR(32) references Seller(Seller_ID)
	,Shipping_Limit_Ts TIMESTAMP
	,Price DECIMAL(6,2)
	,Freight_Val DECIMAL(6,2)
	,primary key(Order_ID,Order_Item_ID)
);

/*-------------------------------------------------------- Order Payment -----------------------------------------------------------------*/
/* Note: - An order may have multiple payment records if multiple payment methods are used (e.g., split payment). 
         - Payment_Seq_No represents the sequence of payment transactions associated with the same order.
*/
create table Order_Payment
(
	 Order_ID VARCHAR(32) NOT NULL references Orders(Order_ID)
	,Payment_Seq_No INTEGER
	,Payment_Type VARCHAR(15)
	,Payment_Installmnt_No INTEGER
	,Payment_Val DECIMAL(10,2)
	,primary key(Order_ID,Payment_Seq_No)
);


/*-------------------------------------------------------- Order Review ------------------------------------------------------------------*/
Create table Order_Review
(
	 Review_ID VARCHAR(32) NOT NULL
	,Order_ID VARCHAR(32) references Orders(Order_ID)
	,Review_Score CHAR(1)
	,Review_Cmt_title VARCHAR(50)
	,Review_Cmt_Msg VARCHAR(250)
	,Review_Creation_Ts TIMESTAMP
	,Review_Answer_Ts TIMESTAMP
	,primary key (Review_ID,Order_ID)
);

