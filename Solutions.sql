use sakila;

-- How many distinct last names of actors are there?
select count(distinct last_name) as distinct_last_name_count from actor;

-- Which actors participated in the movie ‘Academy Dinosaur’? Print their first and last names.
select first_name,last_name from actor
inner join film_actor on actor.actor_id = film_actor.actor_id 
inner join film on film.film_id = film_actor.film_id
where (title) = 'ACADEMY DINOSAUR';

-- How many copies of the film ‘Hunchback Impossible’ exist in the inventory system?
select count(film_id) as hunchback_copies_count from inventory inner join film using(film_id)
where title = 'Hunchback Impossible';

-- What is the total amount paid by each customer for all their rentals? For each customer print their name and the total amount paid.
select sum(amount) as total_amount,concat(first_name,' ',last_name) as fullname from payment inner join customer using(customer_id)
group by customer_id;

-- How many films from each category each store has? Print the store id, category name and number of films. 
-- Order the results by store id and category name.

select count(film_id) as film_count,name as category_name,category_id,store_id from inventory join film using(film_id) inner join film_category using(film_id)
inner join category using(category_id) group by category_id,store_id
order by store_id,category_name;

-- Calculate the total revenue of each store.
select sum(amount) as total_revenue,store_id from store join staff using(store_id) join payment using(staff_id)
group by store_id;

-- Which actor participated in the most films? Print their full name and in how many movies they participated.
select count(film_id) as film_count,concat(first_name,' ',last_name) as full_name from actor join film_actor using (actor_id)
group by actor_id
order by film_count desc limit 1; 

-- Find pairs of actors that participated together in the same movie and print their full names. 
-- Each such pair should appear only once in the result. (You should have 10,385 rows in the result)
select distinct concat(a1.first_name,' ',a1.last_name) as Actor1, concat(a2.first_name,' ', a2.last_name) as Actor2 
from actor a1 inner join film_actor fa1 on fa1.actor_id = a1.actor_id
inner join actor a2 inner join film_actor fa2 on fa2.actor_id = a2.actor_id 
on fa1.film_id=fa2.film_id and a1.actor_id <a2.actor_id
order by Actor1,Actor2;

-- Display the top five most popular films, i.e., films that were rented the highest number of times. 
-- For each film print its title and the number of times it was rented.
select count(rental_id) as rented_count,title from film inner join inventory using(film_id) inner join rental using(inventory_id)
group by film_id
order by rented_count desc limit 5;

-- Is the film ‘Academy Dinosaur’ available for rent from Store 1? 
-- You should check that the film exists as one of the items in the inventory of Store 1, 
-- and that there is no outstanding rental of that item with no return date.
with cte as (select inventory.* from store inner join inventory using(store_id) inner join film using(film_id)
where title ='Academy Dinosaur' and store_id=1)
select Case when count(cte.inventory_id)>0 then 'Yes'
else 'No' end as Available, count(cte.inventory_id) as number_available
 from cte join rental on cte.inventory_id=rental.inventory_id
where return_date is not null;

-- Display the customer names and the total payments they've made, including customers with no payments, using FULL JOIN.
select customer_id,first_name,last_name,sum(amount) as Total_revenue from customer
full join payment using(customer_id) group by customer_id;


-- Count the number of films in each category, assigning a unique row number for each category based on the count using ROW_NUMBER().
select category_id,count(film_id) as count,name, row_number() over(order by category_id) as row_num 
from film join film_category using(film_id) join category using (category_id) group by category_id;

-- Retrieve the customer names and the total payments, ranking them based on payment amounts, and including the LEAD() value for the next customer's payment amount within the same rank.
with c2 as (select first_name,last_name, sum(amount) as total_amount from customer join payment using (customer_id) group by customer_id)
select *, dense_rank() over (order by total_amount desc) as dense__rank, lead(total_amount) over(order by total_amount desc) as next_amount from c2;

-- Display the film titles and their replacement costs, ordering them by replacement costs in ascending order and incorporating the LAG() value for the previous film's replacement cost.
select title,replacement_cost, lag(replacement_cost) over (order by replacement_cost) previous_cost from film;

-- List the first and last names of customers, along with their rental counts, using DENSE_RANK() to assign a dense rank based on the rental counts.
with c2 as (select first_name,last_name, count(customer_id) as count_num from customer join rental using (customer_id) group by customer_id)
select *, dense_rank() over (order by count_num) as dense__rank from c2;

-- Retrieve the film titles and their rental rates, ordering them by rental rates in descending order and including the LEAD() value for the next rental rate.
select title,rental_rate,lead(rental_rate) over (order by rental_rate desc) as next_rental_rate from film;

-- Retrieve the customer names and the total payments, indicating whether the payment was made on a weekday or weekend.
SELECT customer.first_name, customer.last_name, SUM(payment.amount) AS total_payments,
       CASE WHEN DAYOFWEEK(payment.payment_date) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS payment_day_type
FROM customer
JOIN payment ON customer.customer_id = payment.customer_id
GROUP BY customer.customer_id;
-- Advanced Questions:

-- Count the number of rentals made on each day of the week.
SELECT DAYNAME(rental_date) AS rental_day, COUNT(*) AS rental_count
FROM rental
GROUP BY rental_day;


-- Retrieve the film titles and the average days between consecutive rentals for each film.
SELECT title, AVG(DATEDIFF(r2.rental_date, r1.return_date)) AS avg_days_between_rentals
FROM film
LEFT JOIN inventory i ON film.film_id = i.film_id
LEFT JOIN rental r1 ON i.inventory_id = r1.inventory_id
LEFT JOIN rental r2 ON i.inventory_id = r2.inventory_id AND r2.rental_id > r1.rental_id
GROUP BY film.film_id;

-- Display the customer names and the average time between their consecutive rentals.
select first_name,last_name,avg(datediff(r2.rental_date,r1.rental_date)) as avg_time from customer c left join rental r1 on c.customer_id = r1.customer_id
left join rental r2 on c.customer_id = r2.customer_id where r2.rental_id>r1.rental_id
group by c.customer_id;

-- List the film titles and their rental rates, showing the percentage change in rental rates compared to the average rental rate.
with c as (select avg(rental_rate) as average_rental from film)
select title, rental_rate, round(concat(((rental_rate-average_rental)/average_rental)*100,'%'),2) as percentage,average_rental 
from film,c group by film_id;