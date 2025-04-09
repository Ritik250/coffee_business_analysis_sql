-- MONDAY COFFEE --DATA ANALYSIS

select * from city;
select * from customers;
select * from sales;
select * from products;

-- reports and data analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
select city_name, 
	round((population * 0.25)/1000000,2) as coffee_consumers_in_millions, 
	city_rank 
from city 
order by 2 desc;


-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


select ci.city_name, sum(s.total) as total_revenue
from sales s
join customers c
on s.customer_id = c.customer_id
join city ci
on c.city_id = ci.city_id
where extract(year from sale_date) = 2023 
and extract(quarter from sale_date) = 4
group by 1
order by 2 desc

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
select p.product_id,
	p.product_name, 
	count(s.sale_id) as total_orders
from products p 
join sales s 
on p.product_id = s.product_id 
group by 1 
order by 3 desc;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
-- city abd total sale
-- no cx in each these city

SELECT 
  ci.city_name, 
  sum(s.total) as total_revenue,
  count(distinct s.customer_id) as total_cx,
  ROUND(SUM(s.total)::numeric / COUNT(distinct s.customer_id), 2) AS average_sales_per_cx
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;


-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
select ci.city_id,
	ci.city_name, 
	count(c.customer_id) as total_current_cx,  
	round(ci.population * 0.25/1000000,2) as estimated_coffee_consumers_in_millions 
from city ci 
join customers c 
on c.city_id = ci.city_id 
group by 1,2  ;

-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
select * from (
	select ci.city_name, 
		p.product_name, 
		count(s.sale_id) as total_orders, 
		dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as rank
	from sales as s
	join products as p
	on s.product_id = p.product_id
	join customers as c
	on c.customer_id = s.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by ci.city_name, p.product_name
) as t1
where rank<=3


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

with city_table as(
SELECT 
  ci.city_name, 
  sum(s.total) as total_revenue,
  count(distinct s.customer_id) as total_cx,
  ROUND(SUM(s.total)::numeric / COUNT(distinct s.customer_id), 2) AS average_sales_per_cx
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent
as(
select city_name, estimated_rent from city
)
select cr.city_name, 
	cr.estimated_rent, 
	ct.total_cx, 
	ct.average_sales_per_cx, 
	round(cr.estimated_rent::numeric/ct.total_cx,2) as rent_per_cx 
from city_table ct 
join city_rent cr 
on ct.city_name=cr.city_name 
order by 4 desc;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city
with monthly_sales as(
select ci.city_name, 
	extract(year from sale_date) as year, 
	extract(month from sale_date) as month, 
	sum(s.total) as total_sale 
from sales as s 
join customers as c 
on s.customer_id = c.customer_id 
join city ci 
on ci.city_id= c.city_id 
group by 1,2,3 
order by 1,3,2
),
growth_ratio as (
select city_name,
	month, 
	year,
	total_sale as cr_month_sale,
	lag(total_sale,1) over(partition by city_name order by year,month) as last_month_sale
from monthly_sales
)

select city_name, 
	month, year, 
	cr_month_sale, 
	last_month_sale, 
	round(((cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric)*100,2) as growth_rate 
from growth_ratio 
where last_month_sale is not null;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

with city_table as(
SELECT 
  ci.city_name, 
  sum(s.total) as total_revenue,
  count(distinct s.customer_id) as total_cx,
  ROUND(SUM(s.total)::numeric / COUNT(distinct s.customer_id), 2) AS average_sales_per_cx
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
select cr.city_name, 
	ct.total_revenue, 
	cr.estimated_rent as total_rent ,
	ct.total_cx,  
	estimated_coffee_consumer_in_millions, 
	ct.average_sales_per_cx, 
	round(estimated_rent::numeric / total_cx:: numeric,2) as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on cr.city_name=ct.city_name
order by 2 desc


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.
*/
