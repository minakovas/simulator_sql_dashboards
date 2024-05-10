/*
Подсчет числа успешных заказов на пльзователя по дням недели
*/

SELECT weekday_number,
       weekday,
       ROUND(AVG(orders), 2) AS orders_per_user
FROM (
SELECT user_id,
       DATE_PART('isodow', time) AS weekday_number,
       TO_CHAR(time, 'Day') AS weekday,
       COUNT(DISTINCT order_id) AS orders
FROM user_actions
WHERE time::DATE BETWEEN '2022-08-26' AND '2022-09-08'
  AND order_id NOT IN (SELECT order_id 
                       FROM user_actions
                       WHERE action = 'cancel_order')
GROUP BY user_id, weekday_number, weekday
) t
GROUP BY weekday_number, weekday
ORDER BY weekday_number