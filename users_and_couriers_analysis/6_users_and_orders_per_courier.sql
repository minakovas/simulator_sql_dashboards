/*
Подсчет среднего числа активных пользователей и числа заказов на одного курьера в день
*/


SELECT date,
       ROUND(n_paying_users / n_active_couriers::DECIMAL, 2) AS users_per_courier ,
       ROUND(n_orders / n_active_couriers::DECIMAL, 2) AS orders_per_courier 
FROM (
-- число активных пользователей 
SELECT time::DATE AS date, 
       COUNT(DISTINCT user_id) AS n_paying_users
FROM user_actions
WHERE order_id NOT IN (SELECT order_id
                       FROM user_actions
                       WHERE action = 'cancel_order')
GROUP BY date) t1

LEFT JOIN (
-- число активных курьеров
SELECT time::DATE AS date,
       COUNT(DISTINCT courier_id) AS n_active_couriers
FROM courier_actions
WHERE order_id IN (SELECT order_id
                   FROM courier_actions
                   WHERE action = 'deliver_order')
GROUP BY date) t2 USING(date)

LEFT JOIN (
-- число неотмененных заказов
SELECT creation_time::DATE AS date,
       COUNT(order_id) AS n_orders
FROM orders
WHERE order_id NOT IN (SELECT order_id
                       FROM user_actions
                       WHERE action = 'cancel_order')
GROUP BY date) t3 USING(date)

ORDER BY date
