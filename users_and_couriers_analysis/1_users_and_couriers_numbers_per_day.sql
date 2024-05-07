/*
Подсчёт числа новых пользователей и курьеров для каждого дня, 
а также общего числа пользователей и курьеров на каждый день
*/

SELECT new_users_table.date,
       new_users_table.new_users,
       new_couriers_table.new_couriers,
       (SUM(new_users_table.new_users) OVER (
           ORDER BY date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ))::INTEGER AS total_users,
       (SUM(new_couriers_table.new_couriers) OVER (
           ORDER BY date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ))::INTEGER AS total_couriers
FROM 
(
-- новые пользователи
SELECT date,
       COUNT(DISTINCT user_id) AS new_users
FROM (
    SELECT user_id,
           MIN(time::DATE) AS date
    FROM user_actions
    GROUP BY user_id) t
GROUP BY date
) AS new_users_table

FULL JOIN

(
-- новые курьеры
SELECT date,
       COUNT(DISTINCT courier_id) AS new_couriers
FROM (
    SELECT courier_id,
           MIN(time::DATE) AS date
    FROM courier_actions
    GROUP BY courier_id) t
GROUP BY date
) AS new_couriers_table USING(date)

ORDER BY date