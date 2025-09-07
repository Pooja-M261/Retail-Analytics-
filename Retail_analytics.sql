-- Retail Analytics Case Study --
CREATE DATABASE Retail_analytics -- Creating new database

-- Using the database
USE Retail_analytics;

-- Load the entire data into the database
SHOW Tables;

-- Understanding the data structure
DESC customer_profiles; #CustomerID,Age,Gender,Location,JoinDate
DESC product_inventory; #ProductID,ProductName,Category,StockLevel,Price
DESC sales_transaction; #TransactionID,CustomerID,ProductID,QuantityPurchased,TransactionDate

-- Retrieving the data
SELECT * FROM customer_profiles;
SELECT * FROM product_inventory;
SELECT * FROM sales_transaction;

-- Data Cleaning
-- Removal of Duplicates 
-- Query to find duplicates in sales transaction table
SELECT TransactionID,count(*) as Duplicate_entries
FROM sales_transaction
GROUP BY TransactionID
Having Count(*) > 1;

-- Create a new table sales_transcation no_duplicates which contain distinct entries
CREATE TABLE sales_transaction_noduplicates
AS 
SELECT DISTINCT * FROM sales_transaction;

SELECT * FROM sales_transaction_noduplicates;

-- Drop the existing sales_transaction table
DROP TABLE sales_transaction;

-- Rename sales_transaction_noduplicate to sales_transaction
ALTER TABLE sales_transaction_noduplicates
RENAME To sales_transaction;

select * from sales_transaction;

-- Fix Incorrect prices
-- Query to find discrepancies available in price in each product id
-- product_inventory,sales_transaction
Select p.productID,s.TransactionID,s.price as Transactionprice,p.price as Inventoryprice
From sales_transaction s
JOIN product_inventory p on s.productID=p.productID
Where s.price <> p.price;

-- Update the entry of Product ID 51 Transaction price where there is a discrepancy
Update sales_transaction s
SET Price = (select p.price from product_inventory p Where s.productid = p.productid)
Where s.ProductID IN (SELECT p.productid from product_inventory p where p.price <> s.price);

SET SQL_SAFE_UPDATES = 0;

-- Query to find columns with null values
select count(*) as count_null_entries
FROM customer_profiles
where location = '';

select * from sales_transaction;

-- Query to update null values to Unknown value
UPDATE customer_profiles
set location = 'Unknown'
where location ='';

Select * FROM customer_profiles;

-- Handling type mismatch
-- sales transaction ,transaction date is of text type which has to be changed to date

select * FROM sales_transaction;
desc sales_transaction;

Create table sales_transaction_updated as
(select *, str_to_date(trim(TransactionDate),'%d-%m-%Y') as TransactionDate_updated from sales_transaction);

-- Delete the column name TransactionDate from the sales_transaction_table
Alter table sales_transaction
DROP column TransactionDate;

-- EDA = Exploratory Data Analysis
-- PPV
-- Total Sales Summary
Select s.Productid,p.ProductName,SUM(s.QuantityPurchased) as Total_units_sold,SUM(s.QuantityPurchased * s.Price) as TotalSales
From sales_transaction s 
Join Product_inventory p
on s.Productid = p.productid
Group by s.productid,p.Productname
Order by TotalSales DESC;

-- Customer Purchase Frequency
Select Customerid,count(*) as Number_of_transactions
From Sales_transaction
Group by Customerid 
Order by Number_of_transactions DESC;

-- Product Categories Performance
SELECT p.category,SUM(s.QuantityPurchased) as TotalUnitsSold, SUM(s.QuantityPurchased * s.Price) as TotalSales
from sales_transaction s
join product_inventory p
on s.productid = p.productid 
Group by p.category
Order by TotalSales DESC;

-- High Sales Products
select * from sales_transaction;
select productid,sum(price * QuantityPurchased) as TotalRevenue
from sales_transaction
group by productid
order by TotalRevenue DESC
Limit 10;

-- productid , productname,totalrevenue
-- Highest Sales Product
select p.productid,p.productname,sum(s.price * s.QuantityPurchased) as TotalRevenue
from sales_transaction s
join product_inventory p on s.productid = p.productid
group by p.productid,p.productname
order by TotalRevenue DESC
Limit 10;

-- Low Sales Products
select productid,sum(price * QuantityPurchased) as TotalRevenue
from sales_transaction
group by productid
order by TotalRevenue 
Limit 10;

desc sales_transaction;
select 
Transactiondate_updated as Datetrans,count(*) as transaction_count,sum(QuantityPurchased) as TotalUnitsSold,
sum(QunatityPurchased * Price) as TotalSales
From Sales_transaction
Group By Transactiondate_updated
order by Transactiondate_updated desc;

-- Growth Rate of sales
-- Month on month growth percentage
With monthly_sales as(
select month(TransactionDate) as month,sum(QuantityPurchased * Price) as total_sales
from sales_transaction
group by month)
select month,total_sales,LAG(total_sales) over(order by month) as previous_month_sales,
((total_sales- LAG(total_sales) over(order by month))/LAG(total_sales) over(order by month) * 100.0) as mom_growth_percentage 
from monthly_sales

-- High Purchase Frequency
select customerid,count(*) as Number_of_transactions,sum(QuantityPurchased * Price ) as TotalSpent
from sales_transaction
group by customerid
having Number_of_transactions > 10 and TotalSpent > 1000
order by TotalSpent DESC;

-- Occasional Customers => It helps to identify customers who does not make regular purchases
select customerid,count(*) as number_of_transactions,sum(QuantityPurchased * Price) as totalspent
from sales_transaction
group by customerid
having number_of_transactions <=2
order by number_of_transactions ASC , totalspent DESC ;

-- Repeat Purchases => It helps to identify loyal customers who purchases more
select customerid,productid,count(*) as Timespurchased
from sales_transaction
group by customerid,productid
having count(*) > 1
Order by Timespurchased DESC;

-- Loyalty Indicators
select Customerid,min(TransactionDate) as FirstPurchases ,max(TransactionDate) as LastPurchases,
Datediff(max(TransactionDate) ,min(TransactionDate)) as DaysBetweenPurchase
From sales_transaction
group by Customerid
having DaysBetweenPurchase > 0
Order by DaysBetweenPurchase DESC;

-- Customer Segmentation
CREATE TABLE customer_segment as
SELECT Customerid,
CASE WHEN TotalQuantity > 30 then 'High'
When TotalQuantity Between 10 and 30 then 'Mid'
When TotalQuantity Between 1 and 10 then 'low'
else 'none'
End as customersegment
from
(
select a.customerid,sum(b.QuantityPurchased) as TotalQuantity
from customer_profiles a
join sales_transaction b on a.customerid = b.customerid
group by a.customerid) as derived_table;

select * from customer_segment;

select customersegment,count(*)
from customer_segment 
group by customersegment;





