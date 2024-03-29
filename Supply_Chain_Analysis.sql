USE supply_db;

SELECT * FROM Orders;

/* QUESTION 1>. Get the number of orders by the Type of Transaction excluding the orders shipped from Sangli and Srinagar. 
Also, exclude the SUSPECTED_FRAUD cases based on the Order Status,and sort the result in the descending order based on the number of orders.*/


SELECT 
  TYPE AS Type_of_transactions,
  Count(Order_id) AS No_of_orders
FROM
   Orders
WHERE
   Order_City <> 'SANGLI' AND Order_city <> "Srinagar" AND Order_status <> "Suspected Fraud"
GROUP By Type_of_transactions
Order by Count(Order_id) DESC;
   
/* QUESTION 2>. Get the list of the Top 3 customers based on the completed orders along with the following details:

Customer Id

Customer First Name

Customer City

Customer State

Number of completed orders

Total Sales */


select * from orders ;
select * from ordered_items;
select * from customer_info;

-- 1. orderid level sales

SELECT 
    ord.order_id, 
    SUM(sales) AS ord_sales
FROM
    orders AS ord
INNER JOIN
    ordered_items AS itm 
ON 
	ord.order_id = itm.order_id
GROUP BY 
	ord.order_id;


-- Filtering for completed orders only

SELECT 
    ord.order_id, SUM(sales) AS ord_sales
FROM
    orders AS ord
        INNER JOIN
    ordered_items AS itm ON ord.order_id = itm.order_id
WHERE
    order_status = 'Complete'
GROUP BY ord.order_id;

-- Check if the above result is correct

SELECT DISTINCT
    order_id
FROM
    orders
WHERE
    order_status <> 'Complete';

SELECT 
    *
FROM
    ordered_items
WHERE
    order_id IN (20346 , 20368);

-- Customer_id Level Summary  using CTE

WITH order_summary AS
(
	SELECT 
		ord.order_id, 
		sum(sales) AS ord_sales
	FROM 
		orders AS ord
	INNER JOIN
		ordered_items as itm
	ON 
		ord.order_id = itm.order_id
	WHERE 
		order_status = "Complete"
	GROUP BY 
		ord.order_id
)
SELECT 
	* 
FROM 
	order_summary as ord
Inner Join 
	Customer_info as cust
ON 
	ord.customer_id = cust.id;

-- Above query throws an error becausein inner joining wth ordersummary we havent selected the customer id  column while creating the common table expression
-- so we can go back and add customer_od to our common table expression to remove the error

WITH order_summary AS
(
	SELECT
		ord.order_id,
		ord.customer_id,
		sum(sales) as ord_sales
	FROM
		orders as ord
	INNER JOIN
		ordered_items as itm
	ON 
		ord.order_id = itm.order_id
	WHERE 
		order_status = "Complete"
	GROUP BY 
		ord.order_id
)
SELECT * 
FROM 
	order_summary AS ord
INNER JOIN
	Customer_info as cust
ON 
	ord.customer_id = cust.id;

-- Again we dont neeed all this data we only need Customer_id first name , state , city , completed order and total sales so 

WITH order_summary as
(
SELECT 
	ord.order_id,
	ord.customer_id,
	sum(sales) AS ord_sales
FROM
	orders AS ord
INNER JOIN
	ordered_items as itm
ON 
	ord.order_id = itm.order_id
WHERE
	order_status = "Complete"
GROUP BY
	ord.order_id
)
SELECT 
	id AS Customer_id,
	First_name AS Customer_Name,
	City AS Customer_City,
	State AS Customer_State,
	COUNT(DISTINCT order_id) AS Completed_orders,
	Sum(Ord_sales) AS Total_sales
FROM 
	order_summary AS ord
INNER JOIN
	Customer_info as cust
ON 
	ord.customer_id = cust.id
GROUP BY 
	Customer_id, 
	Customer_name, 
	customer_City, 
	Customer_State
ORDER By 
	Completed_orders DESC, 
    Total_sales DESC
LIMIT 3;


-- using dense rank

With Order_summary as
(

	SELECT 
		ord.order_id , 
		sum(sales) AS ord_sales, 
		customer_id
	FROM
	   orders AS ord
	INNER join
	   ordered_items as itm
	ON
	   ord.order_id = itm.order_id
	WHERE
	   order_status = "Complete"
	GROUP BY 
	   ord.order_id
)   
SELECT 
   id AS Customer_id, 
   First_name AS Customer_name, 
   city AS Customer_City , 
   state AS Customer_state ,
   count(Distinct order_id) AS Completed_orders,
   Sum(ord_sales) AS Total_sales,
   DENSE_RANK() OVER(ORDER BY count(Distinct order_id) DESC, Sum(ord_sales) DESC) Top_customers
FROM
   order_summary AS ord
INNER JOIN 
   Customer_info AS cust
ON 
 ord.customer_id = cust.id
GROUP BY 
    Customer_id,
    Customer_name,
    Customer_city,
    Customer_state
LIMIT 3;


-- QUESTION 3>. Get the order count by the Shipping Mode and the Department Name. Consider departments with at least 40 closed/completed orders.


select * from orders;
select* from department;
select* from ordered_items;
select * from product_info;
-- Count(ord.order_id)as order_count

WITH dept_summary AS
(
	SELECT 
		 ord.order_id ,ord.shipping_mode , dept.Name as department_name
	FROM
		orders as ord
	INNER JOIN
		ordered_items as itm
	ON 
		ord.order_id = itm.order_id
	INNER JOIN
		product_info as prod
	ON 
		itm.item_id = prod.Product_Id
	INNER JOIN
		Department as dept 
	ON
		prod.department_id = dept.id
	WHERE
		order_status in('Complete','Closed')
)
SELECT 
	shipping_mode, 
	department_name, 
	count(order_id) AS order_count
FROM 
	dept_summary
GROUP BY 
    shipping_mode, 
    department_name
HAVING 
    COUNT(order_id) >= 40;

/* Question 4>. Create a new field as shipment compliance based on Real_Shipping_Days and Scheduled_Shipping_Days. 
 It should have the following values:

  - Cancelled shipment: If the Order Status is SUSPECTED_FRAUD or CANCELED

  - Within schedule: If shipped within the scheduled number of days 

  - On time: If shipped exactly as per schedule

  - Up to 2 days of delay: If shipped beyond schedule but delayed by 2 days

  - Beyond 2 days of delay: If shipped beyond schedule with a delay of more than 2 days

Which shipping mode was observed to have the highest number of delayed orders?m*/


SELECT * FROM orders;

WITH Shipment_summary AS
(
SELECT 
	 Order_id AS ord,
     Real_Shipping_days,
     Scheduled_shipping_days,
     Shipping_mode,
     Order_status,
    CASE 
		WHEN Order_Status in('Suspected_Fraud', 'Canceled') THEN 'CANCELED SHIPMENT'
        WHEN Real_Shipping_days < Scheduled_shipping_days THEN 'Within Schedule'
		WHEN Real_Shipping_days = Scheduled_shipping_days THEN 'On Time'
		WHEN Real_Shipping_days <=Scheduled_shipping_days +2 THEN 'Upto 2 days of Delay'
        WHEN Real_Shipping_days > Scheduled_shipping_days +3 THEN 'Beyond 2 days of Delay'
        Else "Others"
    END AS Shipment_Compliance
FROM
Orders)
Select 
	COUNT(Ord) As Order_count,
    Shipping_mode
FROM
	Shipment_summary
WHERE 
	Shipment_Compliance in('Upto 2 days of Delay','Beyond 2 days of Delay')
GROUP BY 
	Shipping_Mode
ORDER BY 
	Order_Count DESC
    LIMIT 1;
    
    
/* QUESTION 5 >. An order is canceled when the status of the order is either CANCELED or SUSPECTED_FRAUD. 
Obtain the list of states by the order cancellation% and sort them in the descending order of the cancellation%.
Definition: Cancellation% = Cancelled order / Total orders */


WITH Canceled_orders_summary AS 
(
	SELECT 
		order_state,
        COUNT(order_id) AS Canceled_orders
	FROM
		Orders
	WHERE
		order_status = 'CANCELED' OR order_status = 'SUSPECTED_FRAUD'
	GROUP BY
		order_state
), 
total_order_summary AS 
(
	SELECT 
	  order_state,
	  COUNT(order_id) AS Total_orders
    FROM
	  Orders
    GROUP BY
	  order_state
)
SELECT 
	t.order_state,
    total_orders,
    canceled_orders,
    canceled_orders/total_orders as Cancellation_percentage
FROM 
	canceled_orders_summary as c
RIGHT JOIN
	total_order_summary as t
ON 
	c.order_state = t.order_state
ORDER BY Cancellation_percentage DESC;
    
-- if we use inner join we get ony states common between these two tables
