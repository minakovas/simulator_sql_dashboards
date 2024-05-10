/*
Расчет ARPU, ARPPU, AOV по дням недели
*/

-- отмененные заказы
WITH canceled_orders AS (
SELECT order_id
FROM user_actions
WHERE action = 'cancel_order'
),

-- выручка по дням недели
revenue_per_weekday AS (
SELECT weekday_number,
       weekday,
    --   date,
       SUM(price) AS revenue
FROM (
SELECT order_id,
    --   creation_time::DATE AS date,
       DATE_PART('isodow', creation_time) AS weekday_number,
       TO_CHAR(creation_time, 'Day') AS weekday,
       UNNEST(product_ids) AS product_id
FROM orders
WHERE order_id NOT IN (SELECT * FROM canceled_orders)
  AND creation_time::DATE BETWEEN '2022-08-26' AND '2022-09-08' 
) t
LEFT JOIN products USING(product_id)
GROUP BY weekday_number, weekday  
),

-- число пользователей по дням недели
users_and_orders_numbers AS (
SELECT DATE_PART('isodow', time) AS weekday_number,
       TO_CHAR(time, 'Day') AS weekday,
       COUNT(DISTINCT user_id) AS total_users,
       COUNT(DISTINCT user_id) FILTER(WHERE order_id NOT IN (SELECT * FROM canceled_orders)) AS paying_users,
       COUNT(DISTINCT order_id) FILTER(WHERE order_id NOT IN (SELECT * FROM canceled_orders)) AS successful_orders
FROM user_actions
WHERE time::DATE BETWEEN '2022-08-26' AND '2022-09-08' 
GROUP BY weekday_number, weekday
) 
-- конец CTE


SELECT weekday_number,
       weekday,
       ROUND(revenue / total_users::DECIMAL, 2) AS arpu,
       ROUND(revenue / paying_users::DECIMAL, 2) AS arppu,
       ROUND(revenue / successful_orders::DECIMAL, 2) AS aov
FROM revenue_per_weekday
LEFT JOIN users_and_orders_numbers USING(weekday_number, weekday)
ORDER BY weekday_number
