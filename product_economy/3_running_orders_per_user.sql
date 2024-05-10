/*
Расчет среднего числа заказов на пользователя за все время работы сервиса на каждый день 
*/

SELECT date,
       ROUND(AVG(total_orders), 2) AS avg_orders_per_user
FROM (
    SELECT date,
           user_id,
           SUM(orders) OVER(PARTITION BY user_id ORDER BY date) AS total_orders
    FROM (
        SELECT time::DATE AS date,
               user_id,
               COUNT(DISTINCT order_id) AS orders
        FROM user_actions
        WHERE order_id NOT IN (SELECT order_id
                               FROM user_actions
                               WHERE action = 'cancel_order')
        GROUP BY date, user_id
        ) t1
    ) t2
GROUP BY date
ORDER BY date
