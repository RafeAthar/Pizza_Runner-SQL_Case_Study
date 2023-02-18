/**********************

Case Study Questions

This case study has LOTS of questions - they are broken up by area of focus including:

Pizza Metrics
Runner and Customer Experience
Ingredient Optimisation
Pricing and Ratings
Bonus DML Challenges (DML = Data Manipulation Language)
Each of the following case study questions can be answered using a single SQL statement.

Again, there are many questions in this case study - please feel free to pick and choose which ones you’d like to try!

Before you start writing your SQL queries however - you might want to investigate the data, you may want to do something with some of those null values and data types in the customer_orders and runner_orders tables!

A. Pizza Metrics
How many pizzas were ordered?
How many unique customer orders were made?
How many successful orders were delivered by each runner?
How many of each type of pizza was delivered?
How many Vegetarian and Meatlovers were ordered by each customer?
What was the maximum number of pizzas delivered in a single order?
For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
How many pizzas were delivered that had both exclusions and extras?
What was the total volume of pizzas ordered for each hour of the day?
What was the volume of orders for each day of the week?

B. Runner and Customer Experience
How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
Is there any relationship between the number of pizzas and how long the order takes to prepare?
What was the average distance travelled for each customer?
What was the difference between the longest and shortest delivery times for all orders?
What was the average speed for each runner for each delivery and do you notice any trend for these values?
What is the successful delivery percentage for each runner?

C. Ingredient Optimisation
What are the standard ingredients for each pizza?
What was the most commonly added extra?
What was the most common exclusion?
Generate an order item for each record in the customers_orders table in the format of one of the following:
	Meat Lovers
	Meat Lovers - Exclude Beef
	Meat Lovers - Extra Bacon
	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

D. Pricing and Ratings
If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
What if there was an additional $1 charge for any pizza extras?
	Add cheese is $1 extra
The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
	customer_id
	order_id
	runner_id
	rating
	order_time
	pickup_time
	Time between order and pickup
	Delivery duration
	Average speed
	Total number of pizzas
If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

E. Bonus Questions
If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

************************/


/*****      
								noticed issues and observations in the data:
	1. null values are allowed in every column of every table.
	2. While inserting values, sometimes proper NULL, sometimes 'null' and sometimes, '' is provided. 
	3. although we can understand that there are primary keys and foreign keys, they are not specified while creating tables.
	4. column 'order_time' in table 'customer_orders' is of type TIMESTAMP wheras column 'pickup_time' in table 'runner_orders' is a varchar.
	5. column 'registration_date' in 'runners' table is of type DATE.
	6. 'topping_id' in pizza_toppings, 'toppings' in pizza_recipes, and 'exclusions' & 'extras' in customer_orders seem related.
*****/    

use pizza_runner;
show tables;

											/****	Cleaning Data	****/
update customer_orders set exclusions = null where exclusions in ('null', '');
update customer_orders set extras = null where extras in ('null', '');
update runner_orders set pickup_time = null where pickup_time in ('null', '');
update runner_orders set distance = null where distance in ('null', '');
update runner_orders set duration = null where duration in ('null', '');
update runner_orders set cancellation = null where cancellation in ('null', '');



												-- A. Pizza Metrics
                                                
-- 1. How many pizzas were ordered?
select count(pizza_id) as total_pizzas_ordered
from customer_orders;

-- 2. How many unique customer orders were made?
select count(distinct order_id) as unique_customer_orders
from customer_orders;

-- 3. How many successful orders were delivered by each runner?
select count(*)      -- count(cancellation) will give 0
from runner_orders
where cancellation is null; 

-- 4. How many of each type of pizza was delivered?
select co.pizza_id, count(*) as total_delivered  
from customer_orders co
join runner_orders ro
using (order_id)
where ro.cancellation is null
group by co.pizza_id;
 
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
select pn.pizza_name, count(*) as total_orders
from customer_orders co
join pizza_names pn
using (pizza_id) 
group by pn.pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
select co.order_id, count(*) as pizzas_delivered 
from customer_orders co
join runner_orders ro
using (order_id)
where ro.cancellation is null
group by co.order_id
order by pizzas_delivered desc
limit 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with temp as
	(select *  
	from customer_orders co
	join runner_orders ro
	using (order_id)
	where ro.cancellation is null )
select x.customer_id, x.pizzas_with_atleast_1_change,  y.customer_id, y.pizzas_with_no_change from
(select distinct customer_id, count(*) as pizzas_with_atleast_1_change from temp where exclusions is not null or extras is not null group by customer_id) x
-- join
, (select distinct customer_id,  count(*) as pizzas_with_no_change from temp where not (exclusions is not null or extras is not null) group by customer_id) y
-- on x.customer_id = y.customer_id
;

-- 8. How many pizzas were delivered that had both exclusions and extras?
with temp as
	(select *  
	from customer_orders co
	join runner_orders ro
	using (order_id)
	where ro.cancellation is null )
select count(*) as pizzas_with_exclusion_and_extras_both from temp
where exclusions is not null and extras is not null
;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
select *, extract(hour from order_time) as hour_of_day
from customer_orders
group by hour_of_day
;

-- 10. What was the volume of orders for each day of the week?



											-- B. Runner and Customer Experience
                                            
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- 4. What was the average distance travelled for each customer?
-- 5. What was the difference between the longest and shortest delivery times for all orders?
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- 7. What is the successful delivery percentage for each runner?



											-- C. Ingredient Optimisation

-- 1. What are the standard ingredients for each pizza?
-- 2. What was the most commonly added extra?
-- 3. What was the most common exclusion?
/* 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
		Meat Lovers
		Meat Lovers - Exclude Beef
		Meat Lovers - Extra Bacon
		Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */
/* 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
		For example: "Meat Lovers: 2xBacon, Beef, ... , Salami" */
-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?



											-- D. Pricing and Ratings
                                            
/* 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
		- how much money has Pizza Runner made so far if there are no delivery fees?*/
/* 2. What if there was an additional $1 charge for any pizza extras?
		Add cheese is $1 extra */
/* 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset 
		- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5. */
/* 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
		customer_id
		order_id
		runner_id
		rating
		order_time
		pickup_time
		Time between order and pickup
		Delivery duration
		Average speed
		Total number of pizzas */
/* 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
		- how much money does Pizza Runner have left over after these deliveries? */



													-- E. Bonus Questions
                                                    
/*If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu? */