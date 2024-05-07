/*
Тут смотрим динамику притока новых курьеров и пользователей, а также общего числа пользователей и курьеров для каждого дня 
по сравнению с предыдущим
*/

-- Сохраним результат предыдущего запроса в CTE
WITH users_and_couriers_dynamics AS (
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
)
--  конец CTE


SELECT date,
       new_users,
       new_couriers,
       total_users,
       total_couriers,
       ROUND(((new_users - new_users_prev) / new_users_prev::DECIMAL) * 100, 2) AS new_users_change,
       ROUND(((new_couriers - new_couriers_prev) / new_couriers_prev::DECIMAL) * 100, 2) AS new_couriers_change,
       ROUND(((total_users - total_users_prev) / total_users_prev::DECIMAL) * 100, 2) AS total_users_growth,
       ROUND(((total_couriers - total_couriers_prev) / total_couriers_prev::DECIMAL) * 100, 2) AS total_couriers_growth,
       
       -- проверю, что это то же самое, что и new_users и new_couriers 
       total_users - total_users_prev AS total_users_add,
       total_couriers - total_couriers_prev AS total_couriers_add
FROM 
(
SELECT date,
       new_users,
       new_couriers,
       total_users,
       total_couriers,
       LAG(new_users, 1) OVER (ORDER BY date ASC) AS new_users_prev,
       LAG(new_couriers, 1) OVER (ORDER BY date ASC) AS new_couriers_prev,
       LAG(total_users, 1) OVER (ORDER BY date ASC) AS total_users_prev,
       LAG(total_couriers, 1) OVER (ORDER BY date ASC) AS total_couriers_prev
FROM users_and_couriers_dynamics
) t
ORDER BY date