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
    7. entries in columns 'distance' and 'duration' of table 'runner_order' need to be cleaned. 
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
alter table runner_orders modify column pickup_time timestamp;
alter table runner_orders modify column pickup_time timestamp; 
update runner_orders set distance=replace(distance, 'km', '');
alter table runner_orders modify column distance float;
update runner_orders set duration= left(duration, 2);
alter table runner_orders modify column duration int;
describe runner_orders;


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
	where ro.cancellation is null ), 
    x as
    (select distinct customer_id, count(*) as pizzas_with_atleast_1_change 
    from temp 
    where exclusions is not null or extras is not null 
    group by customer_id),
    y as 
    (select distinct customer_id,  count(*) as pizzas_with_no_change 
    from temp 
    where not (exclusions is not null or extras is not null) 
    group by customer_id)
-- select * from x right join y using(customer_id);
-- /**
select * from
(	select customer_id, pizzas_with_atleast_1_change, pizzas_with_no_change from x left join y using(customer_id)     -- specify columns order, don't use *. 
	union
	select customer_id, pizzas_with_atleast_1_change, pizzas_with_no_change from x right join y using(customer_id)    -- specify columns order. If we use *, MySQl gives different order of columns from above left join query, and hence, union will be wrong. 
) z
order by customer_id;
-- **/

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
select extract(hour from order_time) as hour_of_day, count(pizza_id) as orders_volume
from customer_orders
group by hour_of_day
order by hour_of_day
;

-- 10. What was the volume of orders for each day of the week?
select dayofweek(order_time) as day_of_week, count(pizza_id) as orders_volume
from customer_orders
group by day_of_week
order by day_of_week
;


											-- B. Runner and Customer Experience
                                            
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
with timing as
	(select *, timestampdiff(minute, order_time, pickup_time) as arrival_time_mins
		 from ( 
		 (select distinct order_id, order_time from customer_orders) co
		 join
		 (select distinct order_id, runner_id, pickup_time from runner_orders where pickup_time is not null) ro
		 using(order_id)
		 )
	)
select runner_id, round(avg(arrival_time_mins),2) as avg_arrival_time_mins 
from timing 
group by runner_id
;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
with temp as 
	(select *, timestampdiff(minute, order_time, pickup_time) as order_to_pickup_time_mins
	from customer_orders co
	join
	runner_orders ro
	using(order_id)
	where pickup_time is not null)
select order_id, count(1)as npizzas_ordered, round(avg(order_to_pickup_time_mins),0) as order_to_pickup_time_mins
from temp
group by order_id
order by npizzas_ordered desc
;
	-- It can be observed that in general, as the number of pizzas ordered is increasing, so the time to prepare them. looks like there is some relation.  


-- 4. What was the average distance travelled for each customer?
with temp as
	( select * from customer_orders co
    join
    runner_orders ro
    using(order_id)
    where ro.duration is not null )
select customer_id, round(avg(distance), 2) as avg_distance_travelled_by_runner_km
from temp
group by customer_id
order by avg_distance_travelled_by_runner_km desc;


-- 5. What was the difference between the longest and shortest delivery times for all orders?
select max(duration) - min(duration) as longest_minus_shortest_delivery from runner_orders;

/**   -- another apporach
with 
lt as
	(select max(duration) as longest_time from runner_orders),
st as
	(select min(duration) as shortest_time from runner_orders)
select lt.longest_time - st.shortest_time as longest_minus_shortest_delivery
from lt, st;
**/

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
select *, round(distance/duration,2)  -- runner_id, round( avg(distance/duration), 2) as avg_speed  
from runner_orders
where duration is not null
order by duration desc
-- group by runner_id
;

-- 7. What is the successful delivery percentage for each runner?
with temp as
	( select * from customer_orders co
    join
    runner_orders ro
    using(order_id)
    -- where ro.duration is not null 
    )
select * from temp;



											-- C. Ingredient Optimisation

-- 1. What are the standard ingredients for each pizza?
select *
from pizza_recipes
;

-- 2. What was the most commonly added extra?
select extras from customer_orders;

-- 3. What was the most common exclusion?
select exclusions from customer_orders;

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
with temp as
	(select pizza_id,
    case when co.pizza_id=1 then 10
    else 12
    end as pizza_amount
    from customer_orders co
    join
    runner_orders ro
    using(order_id)
    where ro.cancellation is null
    )
 select sum(pizza_amount) as money_made
 from temp;
        
        
/* 2. What if there was an additional $1 charge for any pizza extras?
		Add cheese is $1 extra */
        
-- case1: any number of extras cost 1$ only
with temp as
	(select pizza_id, extras,
    case when co.pizza_id=1 and extras is null then 10
    when co.pizza_id=1 and extras is not null then 11
    when co.pizza_id=2 and extras is null then 12
    else 13
    end as pizza_amount
    from customer_orders co
    join
    runner_orders ro
    using(order_id)
    where ro.cancellation is null
    )
 select sum(pizza_amount) as money_made
 from temp;
 
-- case 2: each extra adds 1$ to amount.


        
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
