/*
Подсчет числа активных пользователей/курьеров в день,
а также их доли среди всех пользователей/курьеров

Активный пользователь - который создал хотя бы один неотмененный заказ за день
Активный курьер - который принял хотя бы один неотмененный заказ за день
*/


SELECT date,
       paying_users,
       ROUND((paying_users::DECIMAL / SUM(new_users) OVER(ORDER BY date ASC)) * 100, 2) AS paying_users_share,
       active_couriers,
       ROUND((active_couriers::DECIMAL / SUM(new_couriers) OVER(ORDER BY date ASC)) * 100, 2) AS active_couriers_share
FROM (

SELECT COUNT(DISTINCT user_id) AS paying_users,
       time::DATE AS date
FROM user_actions
WHERE order_id NOT IN (SELECT order_id
                       FROM user_actions
                       WHERE action = 'cancel_order')
GROUP BY date
) AS paying_users_t

LEFT JOIN (

SELECT date,
       COUNT(DISTINCT user_id) AS new_users
FROM 
(
SELECT user_id,
       MIN(time::DATE) AS date
FROM user_actions
GROUP BY user_id
) t
GROUP BY date
) AS new_users_t USING(date)

LEFT JOIN (

SELECT COUNT(DISTINCT courier_id) AS active_couriers,
       time::DATE AS date
FROM courier_actions
WHERE order_id IN (SELECT order_id
                   FROM courier_actions
                   WHERE action = 'deliver_order')
GROUP BY date) AS active_couriers_t USING(date)

LEFT JOIN (

SELECT date,
       COUNT(DISTINCT courier_id) AS new_couriers
FROM 
(
SELECT courier_id,
       MIN(time::DATE) AS date
FROM courier_actions
GROUP BY courier_id
) t
GROUP BY date) AS new_couriers_t USING(date)

ORDER BY date
