/*
Расчет долей выручки от старых и новых пользователей
*/

WITH canceled_orders AS (
SELECT order_id
FROM user_actions
WHERE action = 'cancel_order'
)


SELECT date,
       SUM(order_value) AS revenue, 
       SUM(order_value) FILTER (WHERE date = first_date) AS new_users_revenue,
       ROUND((SUM(order_value) FILTER (WHERE date = first_date) / SUM(order_value)::DECIMAL) * 100, 2) AS new_users_revenue_share,
       ROUND(COALESCE((SUM(order_value) FILTER (WHERE date > first_date) / SUM(order_value)::DECIMAL) * 100, 0), 2) AS old_users_revenue_share
FROM (
    SELECT user_id,
           action,
           order_id,
           time::DATE AS date,
           MIN(time::DATE) OVER(PARTITION BY user_id ORDER BY time::DATE) AS first_date
    FROM user_actions
    ) t1
LEFT JOIN (
    SELECT order_id,
           SUM(price) AS order_value
    FROM (
        SELECT order_id,
               UNNEST(product_ids) AS product_id
        FROM orders
        WHERE order_id NOT IN (SELECT * FROM canceled_orders)
        ) t 
    LEFT JOIN products USING(product_id)
    GROUP BY order_id) t2 USING(order_id)
WHERE order_id NOT IN (SELECT * FROM canceled_orders)
GROUP BY date
ORDER BY date
