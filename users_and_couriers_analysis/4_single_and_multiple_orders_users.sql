/*
Подсчет числа пользователей, совершивших один неотмененный заказ и более одного неотмененного заказа в день
*/


SELECT date,
       ROUND((COUNT(DISTINCT user_id) FILTER (WHERE orders_count = 1) / COUNT(DISTINCT user_id)::DECIMAL) * 100, 2) AS single_order_users_share,
       ROUND((COUNT(DISTINCT user_id) FILTER (WHERE orders_count > 1) / COUNT(DISTINCT user_id)::DECIMAL) * 100, 2) AS several_orders_users_share
FROM (
SELECT user_id,
       time::DATE AS date,
       COUNT(order_id) AS orders_count
FROM user_actions
WHERE order_id NOT IN (SELECT order_id
                       FROM user_actions
                       WHERE action = 'cancel_order')
GROUP BY user_id, date
) t
GROUP BY date 
ORDER BY date
