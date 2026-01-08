--Retrive All Data
SELECT * FROM swiggy_data;
--Change in Names & Datatypes
exec sp_help swiggy_data;
ALTER TABLE swiggy_data 
ALTER COLUMN [Rating Count] float NULL;
Exec sp_rename 'swiggy_data.[Rating Count]','Rating_Count'; 


--Data Validation & Cleaning
--Null Check

SELECT 
        SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS NULL_STATE,
        SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS NULL_CITY,
        SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS NULL_ORDER_DATE,
        SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS NULL_RESTRURANT_NAME,
        SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS NULL_LOCATION,
        SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS NULL_CATEGORY,
        SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS NULL_DISH_NAME,
        SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS NULL_PRICE_INR,
        SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS NULL_RATING,
        SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS NULL_RATING_SUM
FROM swiggy_data;


--Blamk & Empty Strings
SELECT * from 
swiggy_data
WHERE State = '' OR City = '' OR Restaurant_Name = '' OR Location = '' OR Category = '' OR Dish_Name = '';


--Duplicate Detection
SELECT STATE,CITY, ORDER_DATE,RESTAURANT_NAME,LOCATION,
CATEGORY,DISH_NAME,PRICE_INR,RATING,RATING_COUNT,
COUNT(*) AS CNT
FROM
swiggy_data
GROUP BY 
STATE,CITY, ORDER_DATE,RESTAURANT_NAME,LOCATION,
CATEGORY,DISH_NAME,PRICE_INR,RATING,RATING_COUNT
HAVING COUNT(*) > 1;



--Delete Duplicate Values

BEGIN TRANSACTION;--(USE THIS BECAUSE IF THERE IS ERROR , ANY CHANCES TO DELTE OTHER DATA USE THIS FOR SAFETY CHECKS)
WITH DUPLICATE_RECORDS AS (

SELECT 
     ROW_NUMBER() OVER(PARTITION BY STATE,CITY, ORDER_DATE,RESTAURANT_NAME,LOCATION,
     CATEGORY,DISH_NAME,PRICE_INR,RATING,RATING_COUNT  ORDER BY PRICE_INR) AS RNK
FROM swiggy_data
)
DELETE DUPLICATE_RECORDS 
WHERE RNK > 1;

COMMIT;

--CREATING SCHEMA
--DIMENSION TABLES
--DATA TABLE

--TABLE NAME = dim_date
CREATE TABLE dim_date
            (
            date_id INT IDENTITY(1,1) PRIMARY KEY,
            Full_Date DATE,
            YEAR INT,
            MONTH INT,
            Month_Name VARCHAR(20),
            Quater INT,
            DAY INT,
            WEEK INT
);

--Data cleaning(till here)
---------------------------------------------------------------------------------------------
SELECT * FROM dim_date;

--TABLE NAME = dim_location
CREATE TABLE dim_location
            (
            location_id INT IDENTITY(1,1) PRIMARY KEY,
            STATE VARCHAR(100),
            CITY VARCHAR(100),
            LOCATION VARCHAR(200)

);
SELECT * FROM dim_location;

----TABLE NAME = dim_restaurant
CREATE TABLE dim_restaurant
            (
            restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
            Restaurant_Name VARCHAR(200)
);
SELECT * FROM  dim_restaurant;

----TABLE NAME = dim_category
CREATE TABLE dim_category
            (
            category_id INT IDENTITY(1,1) PRIMARY KEY,
            Category VARCHAR(200)
);
SELECT * FROM dim_category;


------TABLE NAME = dim_dish
CREATE TABLE dim_dish
            (
            dish_id INT IDENTITY(1,1) PRIMARY KEY,
            Dish_Name VARCHAR(200)
);
SELECT * FROM dim_dish;

--FACT TABLE
CREATE TABLE fact_swiggy_orders 
            (
            order_id INT IDENTITY(1,1) PRIMARY KEY,


            date_id INT,
            Price_INR DECIMAL(10,2),
            Rating  DECIMAL(4,2),
            Rating_Count INT,


            location_id INT,
            restaurant_id INT,
            category_id INT,
            dish_id INT

            FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
            FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
            FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
            FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
            FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)

);
DROP TABLE fact_swiggy_orders;
SELECT * FROM fact_swiggy_orders;


--INSERT DATA INTO TABLES
--dim_date
INSERT INTO dim_date (Full_Date, YEAR, MONTH, Month_Name, Quater,DAY,WEEK)
SELECT DISTINCT
     ORDER_DATE,
     YEAR(ORDER_DATE),
     MONTH(ORDER_DATE),
     DATENAME(MONTH ,ORDER_DATE),
     DATEPART(QUARTER, ORDER_DATE),
     DAY(ORDER_DATE),
     DATEPART(WEEK,ORDER_DATE)
FROM swiggy_data
WHERE Order_Date IS NOT NULL;

SELECT * FROM dim_date;

--dim_location
INSERT INTO dim_location(STATE, CITY,LOCATION)
SELECT DISTINCT
       State,
       City,
       Location
FROM swiggy_data
WHERE Location IS NOT NULL;

SELECT * FROM dim_location;

--dim_restaurant
INSERT INTO dim_restaurant(Restaurant_Name)
SELECT DISTINCT 
       Restaurant_Name
FROM swiggy_data;
SELECT * FROM dim_restaurant;

--dim_category
INSERT INTO dim_category(Category)
SELECT DISTINCT 
       Category
FROM swiggy_data;
SELECT * FROM dim_category;
--dim_category
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT Dish_Name
FROM swiggy_data
WHERE Dish_Name IS NOT NULL;

Select * from dim_dish;

SELECT * FROM fact_swiggy_orders;
--FACT-TABLE
INSERT INTO fact_swiggy_orders
           (
           date_id,
           Price_INR,
           Rating,
           Rating_Count,
           location_id,
           restaurant_id,
           category_id,
           dish_id
)
SELECT
     dd.date_id,
     s.Price_INR,
     s.Rating,
     s.Rating_Count,


     d1.location_id,
     dr.restaurant_id,
     dc.category_id,
     dsh.dish_id
     from swiggy_data s

join dim_date dd
     on dd.Full_Date = s.Order_Date

join dim_location d1
     on d1.STATE = s.State
     and d1.CITY = s.City
     and d1.LOCATION = s.Location

join dim_restaurant dr
     on dr.Restaurant_Name = s.Restaurant_Name

join dim_category dc
     on dc.Category = s.Category

join dim_dish dsh
     on dsh.Dish_Name = s.Dish_Name;



SELECT * FROM dim_category;
SELECT * FROM dim_date;
SELECT * FROM dim_dish;
SELECT * FROM dim_location;
SELECT * FROM dim_restaurant;
SELECT * FROM fact_swiggy_orders;


--Combine all data for viewing purpose(all our table are create in sucessfully and mergerd in one view)
SELECT * FROM fact_swiggy_orders F
JOIN dim_date DD
     ON F.date_id = dd.date_id
JOIN dim_location DL 
     ON F.location_id = DL.location_id
JOIN dim_restaurant DS
     ON F.restaurant_id = ds.restaurant_id
JOIN dim_category DC
     ON F.category_id = DC.category_id
JOIN dim_dish DSH
     ON F.dish_id = DSH.dish_id;

--Data Preparation(For solve any bussiness problem)
-------------------------------------------------------------------------------------------------------------

--SQL Data Analysis
-- KPI Development
--•	Total Orders
    SELECT 
    COUNT(*) AS Count_Orders 
    FROM fact_swiggy_orders;
--•	Total Revenue (INR Million)
    SELECT 
    FORMAT(SUM(CONVERT(FLOAT, Price_INR))/1000000, 'N2') + ' INR Million' 
    Total_Revenue  
    FROM fact_swiggy_orders;

    --Another way
    SELECT 
    SUM(Price_INR) / 1000000 AS Revenue_INR_Million
FROM fact_swiggy_orders;

--•	Average Dish Price
select * from dim_dish;
        SELECT FORMAT(AVG(CONVERT(FLOAT, Price_INR)), 'N2') + ' INR' 
        AS 'Average Dish Price' 
        FROM fact_swiggy_orders;

    --Another way
    SELECT 
    CONCAT(AVG(Price_INR) ,' INR') AS 'Average Dish Price'
FROM fact_swiggy_orders;
--•	Average Rating
SELECT ROUND(AVG(Rating),2) AS Average_rating FROM fact_swiggy_orders;



--Deep-Dive Business Analysis
--Date-Based Analysis
--•	Monthly order trends
    SELECT 
    DD.YEAR,
    DD.MONTH,
    DD.Month_Name,
    COUNT(*) AS Count_Orders
    FROM fact_swiggy_orders F
    JOIN dim_date DD
    ON F.date_id = DD.date_id
    GROUP BY DD.YEAR,
    DD.MONTH,
    DD.Month_Name
    ORDER BY Count_Orders DESC;
--•	Quarterly order trends
    SELECT 
    DD.YEAR,
    DD.Quater,
    COUNT(*) Quaterly_Orders
    FROM fact_swiggy_orders F
    JOIN dim_date DD
    ON F.date_id = DD.date_id
    GROUP BY
    DD.YEAR,
    DD.Quater;
--•	Year-wise growth
    SELECT * FROM fact_swiggy_orders F
    SELECT * FROM dim_date;
    SELECT 
    DD.YEAR,
    COUNT(*) AS Count_Orders,
    CONCAT(SUM(Price_INR),' INR') AS Total_Sales
    FROM fact_swiggy_orders F
    JOIN dim_date DD
    ON F.date_id = DD.date_id 
    GROUP BY YEAR;
--•	Day-of-week patterns
    SELECT * FROM fact_swiggy_orders F
    SELECT * FROM dim_date;
    Select  
    datename(dw, full_date) as Day_Name,
    count(*) Count_Orders
    from fact_swiggy_orders F
    join dim_date dm 
    on f.date_id = dm.date_id
    group by datename(dw, full_date)
    order by Day_Name asc;

--Location-Based Analysis
--•	Top 10 cities by order volume
   SELECT * FROM fact_swiggy_orders F;
   SELECT * FROM dim_location;
   SELECT TOP 10 
   DM.CITY,
   COUNT(*) Order_Volume
   FROM fact_swiggy_orders F
   JOIN dim_location DM
   ON F.location_id = DM.location_id
   GROUP BY DM.CITY
   ORDER BY Order_Volume DESC;
--•	Revenue contribution by states
      SELECT * FROM fact_swiggy_orders F;
      SELECT * FROM dim_location;
      SELECT 
      DL.STATE,
      SUM(Price_INR) AS Total_Revenue
      FROM fact_swiggy_orders F
      JOIN dim_location DL
      ON F.location_id = DL.location_id
      GROUP BY DL.STATE;

--Food Performance
--•	Top 10 restaurants by orders
      SELECT * FROM fact_swiggy_orders F;
      SELECT * FROM dim_restaurant;
      SELECT 
      DR.Restaurant_Name,
      COUNT(*) AS Orders
      FROM fact_swiggy_orders F
      JOIN dim_restaurant DR
      ON F.restaurant_id = DR.restaurant_id
      GROUP BY DR.Restaurant_Name;
--•	Top categories (Indian, Chinese, etc.)
    SELECT
    DC.Category,
    COUNT(*) AS  Total_Orders
    FROM fact_swiggy_orders F
    JOIN dim_category DC
    ON F.category_id = DC.category_id
    GROUP BY DC.Category
    ORDER BY Total_Orders DESC;

--•	Most ordered dishes
    SELECT 
    DSH.Dish_Name,
    COUNT(*) Total_Orders
    FROM fact_swiggy_orders F
    JOIN dim_dish DSH
    ON F.dish_id = DSH.dish_id
    GROUP BY DSH.Dish_Name
    ORDER BY Total_Orders DESC;
--•	Cuisine performance ? Orders + Avg Rating
      SELECT 
      COUNT(*) AS  Total_Orders,
      FORMAT(AVG(CONVERT(FLOAT,Rating)), 'N2') + ' INR' AS  Average_Rating
      FROM fact_swiggy_orders F;
      
--Customer Spending Insights
--Buckets of customer spend:
--•	Under 100
       SELECT 
       F.Order_id,
       F.Price_INR
       FROM fact_swiggy_orders F
       WHERE Price_INR < 100;
--•	100–199
       SELECT 
       F.Order_id,
       F.Price_INR
       FROM fact_swiggy_orders F
       WHERE Price_INR BETWEEN 100  AND  199;
--•	200–299
       SELECT 
       F.Order_id,
       F.Price_INR
       FROM fact_swiggy_orders F
       WHERE Price_INR BETWEEN 200  AND  299;
--•	300–499
       SELECT 
       F.Order_id,
       F.Price_INR
       FROM fact_swiggy_orders F
       WHERE Price_INR BETWEEN 300  AND  499;
--•	500+
       SELECT 
       F.Order_id,
       F.Price_INR
       FROM fact_swiggy_orders F
       WHERE Price_INR >= 500;
--With total order distribution across these ranges.
--Ratings Analysis
--Distribution of dish ratings from 1–5.
   SELECT 
   F.Rating,
   COUNT(*) AS Rating_Count
   FROM fact_swiggy_orders F
   GROUP BY F.Rating 
   ORDER BY Rating_Count;
 