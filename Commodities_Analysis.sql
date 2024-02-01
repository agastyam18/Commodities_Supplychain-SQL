USE commodity_db;

SELECT * from commodities_info;
SELECT * from price_details;
SELECT * from region_info;


/* QUESTION 1>. Outline the common commodities between the top 10 costliest commodities of 2019 and 2020 */


-- FIltering data for years first

SELECT 
    Commodity_id,
    MAX(Retail_Price) as Price
FROM 
	price_details
WHERE 
	YEAR(date) = 2019
GROUP BY 
	Commodity_id
ORDER BY 
	Price DESC;
    
    
SELECT 
    Commodity_id,
    MAX(Retail_Price) as Price
FROM 
	price_details
WHERE 
	YEAR(date) = 2020
GROUP BY 
	Commodity_id
ORDER BY 
	Price DESC;

-- NEXT STEP

WITH Price_summary_19 AS
(
	SELECT 
		Commodity_id,
		MAX(Retail_Price) as Price
	FROM 
		price_details
	WHERE 
		YEAR(date) = 2019
	GROUP BY 
		Commodity_id
	ORDER BY 
		Price DESC
	LIMIT 10
),
Price_summary_20 AS
(
	SELECT 
		Commodity_id,
		MAX(Retail_Price) as Price
	FROM 
		price_details
	WHERE 
		YEAR(date) = 2020
	GROUP BY 
		Commodity_id
	ORDER BY 
		Price DESC
	LIMIT 10
),
Common_Summary AS
(
	SELECT 
		p19.commodity_id
	FROM
		Price_summary_19 AS p19
	INNER JOIN 
		Price_summary_20 AS P20
	ON 
		p19.commodity_id = p20.commodity_id
)
SELECT  DISTINCT Commodity  -- USED Distinct to get unique commodity values
FROM 
	Commodities_info AS inf
INNER JOIN 
	Common_summary AS com
ON
	inf.id = com.commodity_id;


/*  QUESTION 2>. Find the maximum difference between the prices of a commodity month of June 2020 ? */


-- Checking all tables together by joining 

SELECT 
    *
FROM
    price_details AS p
INNER JOIN
    commodities_info AS c ON c.id = p.commodity_id
INNER JOIN
    region_info AS r ON p.id = r.id;
    
-- Extracting Minimum and maximum prices from retail price info columns for the moth of june 2020

SELECT 
	Commodity_id,
	MIN(retail_price) as Min_price,
    MAX(retail_price) as Max_price
FROM 
	Price_details
WHERE
	Date BETWEEN '2020-06-01' AND '2020-06-30'
GROUP BY 
	Commodity_id;

-- Calculating the  Maximum differecne

WITH June_prices AS
(
SELECT 
	Commodity_id,
	MIN(retail_price) as Min_price,
    MAX(retail_price) as Max_price
FROM 
	Price_details
WHERE
	Date BETWEEN '2020-06-01' AND '2020-06-30'
GROUP BY 
	Commodity_id
)
SELECT 
	Commodity,
    max_price - min_price AS Price_Difference
FROM 
	Commodities_info AS c
INNER JOIN
	June_prices AS J
ON
	c.id = j.commodity_id
ORDER BY 
	Price_difference DESC
LIMIT 1;

/* Question 3>. A table that shows all the commodities sorted in decreasing order of the number of varieties available. 
                Which would be The third commodity in this list .*/
   
SELECT 
	DISTINCT Commodity,
	Count(Variety) as Variety_count
FROM 
	Commodities_info
Group By 
	commodity
ORDER BY 
	Variety_Count DESC;

/* Question 4>.Find out the state with the least number of entries, that is, where the company has minimum presence amongst all other states. 
                Then, within that state, we have to find out the commodity with the highest number of data points available.*/


SELECT
	p.*,r.state 
FROM
	price_details AS P
LEFT JOIN                 -- DID left join because we need all values for particular region including null values.
	region_info as r
ON
	p.region_id = r.id;



WITH State_Summary as
(
	SELECT
		p.*,r.state 
	FROM
		price_details AS P
	LEFT JOIN                 
		region_info as r
	ON
		p.region_id = r.id
),
State_count as 
(
	SELECT 
		COUNT(id) as Statewise_count,
		commodity_id,
		state
	FROM
		State_summary
	GROUP BY 
		State
	ORDER BY
		Statewise_count
	LIMIT 1 -- -- State which has lowest entriesis Arunachal Pradesh
),
commodity_list AS
(
	SELECT 
		commodity_id,
		COUNT(id) AS record_count
	FROM 
		State_summary
	WHERE 
		state IN (SELECT DISTINCT state FROM state_count)
	GROUP BY 
		commodity_id
	ORDER BY 
		record_count DESC ''
)
SELECT
	commodity,
	SUM(record_count) AS record_count
FROM
	commodity_list AS c
LEFT JOIN
	commodities_info AS ci
ON 
	c.commodity_id = ci.id
GROUP BY 
	commodity
ORDER BY 
	record_count DESC
LIMIT 1;
 
 
 
 /* Question 5>. Measure the price variation for each commodity in each city between January 2019 and December 2020. 
				Price variation is the relative change of price in December 2020 compared to January 2019. 
				After we get the price variation for all commodities in each city, we need to find out the commodity along with the city’s name that has maximum price variation */




-- Extracting Data for january and december 2020

WITH Jan_2019 AS
(
	SELECT * 
	FROM
		Price_details
	WHERE 
		date BETWEEN '2019-01-01' AND '2019-01-31'
),
 DEC_2020 AS   
(    
	SELECT *
	FROM
		Price_details
	WHERE
		date BETWEEN '2020-12-01' AND '2020-12-31'
),
Price_Variation As
(
   SELECT 
		j.region_id,
		j.commodity_id,
		j.Retail_price as Start_price,
		d.Retail_price as End_Price,
        d.Retail_price - j.Retail_price AS Variation,
        ROUND((d.Retail_price - j.Retail_price)/j.Retail_price*100,2) AS Variation_Percentage
	FROM    
		jan_2019 as j
	INNER JOIN
		DEC_2020 as D
	ON
		J.region_id = d.region_id
	AND
		j.commodity_id = d.commodity_id
	ORDER BY 
		Variation_Percentage DESC
	LIMIT 1
)
Select
    r.centre AS CITY,
	c.commodity As Commodity_Name,
    Start_Price,
    End_Price,
    Variation,
    Variation_Percentage
FROM
	price_variation as p
INNER JOIN
	region_info as r
ON
	p.region_id = r.id
INNER JOIN
	commodities_info AS C
ON 
	p.commodity_id = c.id;