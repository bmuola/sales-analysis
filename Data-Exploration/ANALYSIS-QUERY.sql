-- Create the 'sales' schema
CREATE SCHEMA IF NOT EXISTS sales;

-- Create the 'raw_data' table to store sales data
-- 1st instance input
DROP TABLE IF EXISTS project_sales_001.sales.raw_data;
CREATE TABLE project_sales_001.sales.raw_data (
    Date DATE,
    Day INT,
    Month VARCHAR(255),
    Year INT,
    Customer_age INT,
    Age_group VARCHAR(255),
    Customer_gender VARCHAR(255),
    Country VARCHAR(255),
    State VARCHAR(255),
    Product_category VARCHAR(255),
    Sub_category VARCHAR(255),
    Product VARCHAR(255),
    Order_quantity INT,
    Unit_cost INT,
    Unit_price INT,
    Profit INT,
    Cost INT,
    Revenue INT
);

-- Indexes on frequently used columns
-- Index on 'Country' column
CREATE INDEX idx_raw_data_country ON project_sales_001.sales.raw_data (Country);

-- Index on 'Year' column
CREATE INDEX idx_raw_data_year ON project_sales_001.sales.raw_data (Year);

-- Index on 'Product' column
CREATE INDEX idx_raw_data_product ON project_sales_001.sales.raw_data (Product);

-- Import data from CSV file into the 'raw_data' table
COPY project_sales_001.sales.raw_data 
FROM 'C:\Users\Ben\Downloads\sales_data.csv' DELIMITER ',' CSV HEADER;

-- View the data in the 'raw_data' table
SELECT * FROM project_sales_001.sales.raw_data;

-- Materialized view for revenue by gender
-- 2nd instance input
CREATE MATERIALIZED VIEW revenue_by_gender AS
SELECT Customer_gender AS Gender,
       SUM(Revenue) AS Total_Revenue
FROM project_sales_001.sales.raw_data
GROUP BY Gender;

-- Materialized view for revenue by country
-- 3rd instance input
CREATE MATERIALIZED VIEW revenue_by_country AS
SELECT Country,
       SUM(Revenue) AS Total_Revenue
FROM project_sales_001.sales.raw_data
GROUP BY Country;

-- Materialized view for revenue by age group
-- 4th instance input
CREATE MATERIALIZED VIEW revenue_by_age AS
SELECT Age_group,
       SUM(Revenue) AS Total_Revenue
FROM project_sales_001.sales.raw_data
GROUP BY Age_group;

-- Materialized view for sales trend over the years
-- 5th instance input
CREATE MATERIALIZED VIEW sales_trend AS
SELECT Year,
       SUM(Order_quantity) AS Total_Sales
FROM project_sales_001.sales.raw_data
GROUP BY Year;

-- Materialized view for best selling products over the years
-- 6th instance input
CREATE MATERIALIZED VIEW best_selling AS
SELECT Year,
       Product,
       SUM(Order_quantity) AS Total_Quantity
FROM project_sales_001.sales.raw_data
GROUP BY Year, Product
HAVING SUM(Order_quantity) = (
    SELECT MAX(Sum_Order_Quantity)
    FROM (
        SELECT Year,
               Product,
               SUM(Order_quantity) AS Sum_Order_Quantity
        FROM project_sales_001.sales.raw_data
        GROUP BY Year, Product
    ) AS subquery
    WHERE subquery.Year = project_sales_001.sales.raw_data.Year
)
ORDER BY Year;

-- Materialized view for analyzing and visualizing product subcategories in the country with the least amount of revenue
-- 7th instance input
CREATE MATERIALIZED VIEW investments AS
WITH country_revenue AS (
    SELECT Country,
           SUM(Revenue) AS Total_Revenue
    FROM project_sales_001.sales.raw_data
    GROUP BY Country
    ORDER BY Total_Revenue
    LIMIT 1
)
SELECT
    cr.Country,
    rd.Sub_category,
    SUM(rd.Revenue) AS Subcategory_Revenue
FROM
    project_sales_001.sales.raw_data AS rd
    JOIN country_revenue AS cr ON rd.Country = cr.Country
GROUP BY
    cr.Country,
    rd.Sub_category
ORDER BY
    Subcategory_Revenue DESC
LIMIT 3;

-- Materialized view for analyzing and visualizing sales in quarters across the years
-- 8th instance input
CREATE MATERIALIZED VIEW sales_on_quarters AS
SELECT
    Year,
    CASE
        WHEN Month IN ('January', 'February', 'March') THEN 'Q1'
        WHEN Month IN ('April', 'May', 'June') THEN 'Q2'
        WHEN Month IN ('July', 'August', 'September') THEN 'Q3'
        WHEN Month IN ('October', 'November', 'December') THEN 'Q4'
    END AS Quarter,
    SUM(Order_quantity) AS Total_Quantity
FROM
    project_sales_001.sales.raw_data
GROUP BY
    Year, Quarter
ORDER BY
    Quarter;

--Now let's view the top five best selling products for every year
-- 9th instance input
SELECT Year, Product, Revenue
FROM (
    SELECT Year, Product, SUM(revenue) AS Revenue,
        ROW_NUMBER() OVER (PARTITION BY Year ORDER BY SUM(revenue) DESC) AS rn
    FROM project_sales_001.sales.raw_data
    GROUP BY Year, product
) ranked_data
WHERE rn <= 5
ORDER BY Year DESC, Revenue DESC;
