/*
Подсчет ARPU, ARPPU, AOV, paying_share
*/


-- Выручка сервиса за каждый день
WITH daily_revenue_t AS (
SELECT unnested_orders_t.date,
       SUM(products.price) AS revenue
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


-- Отмененные заказы
canceled_orders AS (
SELECT order_id
FROM user_actions
WHERE action = 'cancel_order'
),


-- Число пользователей (которые сделали любое действие), число платящих пользователей (которые сделали неотмененный заказ) и число неотмененных заказов
users_and_orders_t AS (
SELECT time::DATE AS date,
       COUNT(DISTINCT user_id) AS total_users,
       COUNT(DISTINCT user_id) FILTER (WHERE order_id NOT IN (SELECT * FROM canceled_orders)) AS paying_users,
       COUNT(DISTINCT order_id) FILTER (WHERE order_id NOT IN (SELECT * FROM canceled_orders)) AS successful_orders
FROM user_actions
GROUP BY date
)
-- Конец CTE


SELECT date,
       ROUND(daily_revenue_t.revenue / users_and_orders_t.total_users::DECIMAL, 2) AS arpu,
       ROUND(daily_revenue_t.revenue / users_and_orders_t.paying_users::DECIMAL, 2) AS arppu,
       ROUND(daily_revenue_t.revenue / users_and_orders_t.successful_orders::DECIMAL, 2) AS aov,
       ROUND((users_and_orders_t.paying_users / users_and_orders_t.total_users::DECIMAL) * 100, 2) AS paying_share  
FROM daily_revenue_t
LEFT JOIN users_and_orders_t USING(date)
ORDER BY date
