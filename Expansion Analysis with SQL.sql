-- ------------------------------------------------------------Problem Staement for the Monday Coffee Expansion Analysis-----------------------------------------------------------------------------


/* The Monday Coffee Company sells coffee and coffee products online. The sales entail; coffee, mugs, tshirts and any other coffee rerlated product. The company uses its website to do the sales,
 and they now want to expand their business in three Indian major cities. The company has provided sales data for the last one and half years and they need an analysis to determine the three cities
which they should expand into and why they should expand into them. 
*/

CREATE DATABASE MondayCoffee;

-- Creating the relevant tables -- 

CREATE TABLE City
(
	CityId	INT PRIMARY KEY,
	CityName VARCHAR(15),	
	Population	BIGINT,
	EstimatedRent	FLOAT,
	CityRank INT
);

CREATE TABLE Customers
(
	CustomerId INT PRIMARY KEY,	
	CustomerName VARCHAR(25),	
	CityId INT,
	CONSTRAINT FkCity FOREIGN KEY (CityId) REFERENCES City(CityId)
);


CREATE TABLE Products
(
	ProductId INT PRIMARY KEY,
	ProductName VARCHAR(35),	
	Price FLOAT
);


CREATE TABLE Sales
(
	SaleId INT PRIMARY KEY,
	SaleDate DATE,
	ProductId INT,
	CustomerId INT,
	Total FLOAT,
	Rating INT,
	CONSTRAINT FkProducts FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
	CONSTRAINT FkCustomers FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId) 
);


-- Monday Coffee Business  Analytics -- Business Problem solutions  ------ 

/* Query 1 Coffee Customer Count
How many people in each city are estimated to consume coffee, given that 25% of the population does?
*/

SELECT CityName, 
round(((0.25*Population)/1000000),3) AS EstimatedConsumersInMillions
FROM City
ORDER BY 2 DESC;

/* Query 2 Total Revenue From Coffee Sales
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023
*/
-- City == Customer == Sales 

-- Approach 1 - Specifying the dates between october and december

SELECT CityName,
       SUM(Total) AS TotalRevenue
FROM City AS Ci
JOIN Customers AS Cu
ON Ci.CityId = Cu.CityId
JOIN Sales AS S 
ON S.CustomerId = Cu.CustomerId
WHERE SaleDate <= "2023-12-31" AND SaleDate >= "2023-10-01" 
GROUP BY 1
ORDER BY TotalRevenue DESC;

-- Approach 2 - Extracting year and quarter from the sales date and giving year condition as 2023 and quarter condition as 4 -- 

SELECT CityName,
       SUM(Total) AS TotalRevenue
FROM City AS Ci
JOIN Customers AS Cu
ON Ci.CityId = Cu.CityId
JOIN Sales AS S 
ON S.CustomerId = Cu.CustomerId
WHERE YEAR(SaleDate) = 2023  AND QUARTER(SaleDate) = 4
GROUP BY 1
ORDER BY TotalRevenue DESC;

/* Query 3 -  Sales Count For Each Product 
How many Units of each coffee product have been sold
*/

-- Sales == Products 

SELECT S.ProductId,
	   ProductName,
       COUNT(S.ProductId) AS TotalUnits
FROM Products AS P
JOIN Sales AS S
ON P.ProductId  = S.ProductId
GROUP BY 1,2
ORDER BY TotalUnits DESC;

/* Query 4 -  Average Sales Amount Per City
What is the average sales amount per customer in each city?
*/


SELECT C.CityName,
	   SUM(S.Total) AS TotalRevenue,
       COUNT(DISTINCT S.CustomerId) AS TotalCustomers,
       round(SUM(S.Total)/COUNT(DISTINCT S.CustomerId),0) AS AvgSaleAmontPerCustomer
FROM Sales as S
JOIN Customers AS Cu
ON S.CustomerId = Cu.CustomerId
JOIN City AS C 
ON C.CityId = Cu.CityId
GROUP BY 1
ORDER BY AvgSaleAmontPerCustomer DESC;

/* -- -- Q.5
City Population and Coffee Consumers (25%)
Provide a list of cities along with their populations and estimated coffee consumers.
return city_name, total current cx, estimated coffee consumers (25%)
*/

SELECT CityName,
       COUNT(DISTINCT S.CustomerId) AS TotalCurrentCx,
       ROUND((C.Population*0.25)/1000000,3) AS EstimatedCosumersInMillions
FROM City AS C
JOIN Customers AS Cu
ON C.CityId = Cu.CityId
JOIN Sales AS S 
ON S.CustomerId = Cu.CustomerId
GROUP BY 1,3
ORDER BY 3 DESC;

/* Query 6 -  Top Selling Products By City
What are the top 3 selling products in each city based on sales volume?
*/
-- Sales == City == Customers == Products 

CREATE TABLE ProductCityRank
       AS 
SELECT C.CityName,
       P.ProductId, 
       P.ProductName,
       COUNT(S.SaleId) AS TotalOrders,
       DENSE_RANK() OVER(PARTITION BY CityName ORDER BY COUNT(S.SaleId) DESC)  AS ProductCityRank 
FROM Sales AS S
JOIN Customers as Cu
ON Cu.CustomerId = S.CustomerId
JOIN City AS C 
ON C.CityId = Cu.CityId
JOIN Products AS P
ON P.ProductId = S.ProductId
GROUP BY 1,2,3
ORDER BY 1,TotalOrders DESC;

SELECT * FROM ProductCityRank
WHERE ProductCityRank <= 3; 

/* Query 7 -- Customer Segmentation By City
How many unique customers are there in each city who have purchased coffee products?
*/

-- City == Customers == Sales 

SELECT CityName,
       COUNT(DISTINCT S.CustomerId) AS UniqueCustomers
FROM City AS C
JOIN Customers AS Cu
ON Cu.CityId = C.CityId
JOIN Sales AS S 
ON S.CustomerId = CU.CustomerId
WHERE S.ProductId <= 14
GROUP BY 1
ORDER BY 2 DESC;


/* Query 8 Average Sales Vs Rent
Find each city and their average sale per customer and avg rent per customer
*/
-- City == Sales == Customers


SELECT C.CityName,
       EstimatedRent,
      -- SUM(S.Total) AS TotalCitySales,
       COUNT(DISTINCT Cu.CustomerId) AS TotalCityCustomers,
       ROUND(SUM(S.Total)/COUNT(DISTINCT Cu.CustomerId),2) AS AvgSalePerCustomer,
       ROUND(EstimatedRent/COUNT(DISTINCT Cu.CustomerId),2) AS AvgRentPerCustomer
FROM City AS C
JOIN Customers AS Cu
ON Cu.CityId = C.CityId
JOIN Sales AS S 
ON S.CustomerId = Cu.CustomerId
GROUP BY 1,2
ORDER BY 4 DESC;


/* Query 9 Monthly Sales Growth
Calculate the Percentage growth (or decline) in sales over different time periods(monthly) in each of the cities
*/
-- City == Sales == Customers


WITH MonthlySales 
       AS 
(
			SELECT C.CityName,
				   MONTH(S.SaleDate) AS Month,
                   YEAR(S.SaleDate) AS Year,
                   SUM(S.Total) AS TotalSales
            FROM Sales AS S
            JOIN Customers AS Cu
			ON S.CustomerId = Cu.CustomerId
            JOIN City AS C 
            ON C.CityId = Cu.CityId
            GROUP BY 1,2,3
            ORDER BY 1,3,2
),
GrowthRatio 
AS 
(
      SELECT
		   CityName,
           Month,
           Year,
           TotalSales AS CurrentMonthSale,
           LAG(TotalSales,1) OVER(PARTITION BY CityName ORDER BY Year,Month) AS LastMonthSale
	  FROM MonthlySales
)

SELECT 
     CityName,
     Month,
     Year,
     CurrentMonthSale,
     LastMonthSale,
     ROUND(
	      (CAST(CurrentMonthSale AS DECIMAL(10,2)) - CAST(LastMonthSale AS DECIMAL(10,2)))
          / NULLIF(CAST(LastMonthSale AS DECIMAL(10,2)), 0) * 100,
          2
    ) AS GrowthRatio
FROM GrowthRatio
WHERE LastMonthSale IS NOT NULL
ORDER BY CityName,Year,Month;




-- 2nd Approach with Month Name as Well for easier Reference and Reporting ----------------------

WITH MonthlySales AS (
    SELECT 
        C.CityName,
        MONTHNAME(S.SaleDate) AS MonthName,
        MONTH(S.SaleDate) AS MonthNum,
        YEAR(S.SaleDate) AS Year,
        SUM(S.Total) AS TotalSales
    FROM Sales AS S
    JOIN Customers AS Cu ON S.CustomerId = Cu.CustomerId
    JOIN City AS C ON C.CityId = Cu.CityId
    GROUP BY C.CityName, MONTHNAME(S.SaleDate), MONTH(S.SaleDate), YEAR(S.SaleDate)
),

GrowthRatio AS (
    SELECT
        CityName,
        MonthName,
        MonthNum,
        Year,
        TotalSales AS CurrentMonthSale,
        LAG(TotalSales, 1) OVER (PARTITION BY CityName ORDER BY Year, MonthNum) AS LastMonthSale
    FROM MonthlySales
)

SELECT 
    CityName,
    MonthName AS Month,
    Year,
    CurrentMonthSale,
    LastMonthSale,
    ROUND(
        (CAST(CurrentMonthSale AS DECIMAL(10,2)) - CAST(LastMonthSale AS DECIMAL(10,2))) /
        NULLIF(CAST(LastMonthSale AS DECIMAL(10,2)), 0) * 100,
        2
    ) AS GrowthRatio
FROM GrowthRatio
WHERE LastMonthSale IS NOT NULL
ORDER BY CityName, Year, MonthNum;


-- Query.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

-- City == Sales == Customers

SELECT C.CityName,
       Sum(S.Total) AS TotalSales,
       C.EstimatedRent,
       COUNT(DISTINCT S.CustomeriD) AS TotalCustomers,
       ROUND((C.Population*0.25)/1000000,3) AS EstimatedConsumersInMillions,
       ROUND(Sum(S.Total)/COUNT(DISTINCT S.CustomeriD),2) AS AvgSalePerCx,
       ROUND(C.EstimatedRent/COUNT(DISTINCT S.CustomeriD),2) AS AvgRentPerCx
FROM City AS C
JOIN Customers AS Cu
ON Cu.CityId = C.CityId
JOIN Sales AS S 
ON S.CustomerId = Cu.Customerid
GROUP BY 1,3,5
ORDER BY 2 DESC;



/* Recommendations
City 1: Pune
	 1.Average rent per customer is very less
     2.Highest total revenue
     3.Average sales per customer is also high
     
City 2: Delhi
     1. Highest Estimated coffee consumer which is 7.7m
     2. Highest total customers with 68
     3. Average rent per customer of 330 is quite favourable, it is below 500


City 3: Jaipur
	 1. Highest customer base of 69
     2. Average rent per customer is the lowest amongst the cities at 156
     3. Average sale per customer of 11644 is among the top 4
     
     
     
     
     
     
     -- -----------------------------------------------------------------END OF MONDAY COFFEE EXPANSION ANALYSIS-----------------------------------------------------------------------------------

       
       




        
           








       
       
       
