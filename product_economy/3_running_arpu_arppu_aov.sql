/*
Расчет Running ARPU, ARPPU и AOV
*/

WITH daily_revenue_t AS (
SELECT unnested_orders_t.date,
       SUM(SUM(products.price)) OVER(ORDER BY unnested_orders_t.date) AS cumulative_revenue
FROM ( 
    SELECT order_id,
           creation_time::DATE AS date,
           product_ids,
           UNNEST(product_ids) AS product_id
    FROM orders
    WHERE order_id NOT IN (SELECT order_id
                           FROM user_actions
                           WHERE action = 'cancel_order')
    ) unnested_orders_t
LEFT JOIN products USING(product_id)
GROUP BY unnested_orders_t.date
),

-- Общее число пользователей
total_users_t AS (
SELECT date,
      SUM(COUNT(DISTINCT user_id)) OVER(ORDER BY date) AS cumulative_total_users
FROM (
    SELECT user_id,
          MIN(time::DATE) AS date
    FROM user_actions
    GROUP BY user_id
) t
GROUP BY date
),

-- Отмененные заказы
canceled_orders AS (
SELECT order_id 
FROM user_actions 
WHERE action = 'cancel_order'
),

-- Число активных пользователей
paying_users_t AS (
SELECT date,
       SUM(COUNT(DISTINCT user_id)) OVER(ORDER BY date) AS cumulative_paying_users
FROM (
    SELECT user_id,
           MIN(time::DATE) AS date
    FROM user_actions
    WHERE order_id NOT IN (SELECT * FROM canceled_orders)
    GROUP BY user_id
) t
GROUP BY date
),

-- Число успешных заказов
sucessful_orders_t AS (
SELECT time::DATE AS date,
       SUM(COUNT(DISTINCT order_id)) OVER(ORDER BY time::DATE) AS cumulative_successful_orders
FROM user_actions
WHERE order_id NOT IN (SELECT * FROM canceled_orders)
GROUP BY date
)



SELECT date,
       ROUND(cumulative_revenue / cumulative_total_users, 2) AS running_arpu,
       ROUND(cumulative_revenue / cumulative_paying_users, 2) AS running_arppu,
       ROUND(cumulative_revenue / cumulative_successful_orders, 2) AS running_aov
FROM daily_revenue_t
LEFT JOIN total_users_t USING(date)
LEFT JOIN paying_users_t USING(date)
LEFT JOIN sucessful_orders_t USING(date)
ORDER BY date
