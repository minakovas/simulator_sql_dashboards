WITH canceled_orders AS (
SELECT order_id
FROM user_actions
WHERE action = 'cancel_order'
)
-- конец CTE


SELECT date,
       orders,
       first_orders,
       new_users_orders,
       ROUND((first_orders::DECIMAL / orders) * 100, 2) AS first_orders_share,
       ROUND((new_users_orders::DECIMAL / orders) * 100, 2) AS new_users_orders_share
FROM (

-- Считаем first_orders
SELECT date,
       COUNT(user_id) AS first_orders
FROM (
    SELECT user_id,
           MIN(time::DATE) AS date
    FROM user_actions
    WHERE order_id NOT IN (SELECT * FROM canceled_orders)
    GROUP BY user_id) t
GROUP BY date
) t1

-- Считаем new_users_orders
LEFT JOIN (
SELECT user_actions.time::DATE AS date,
       COUNT(user_actions.user_id) AS new_users_orders
FROM user_actions
-- Делаем INNER JOIN, чтобы для каждого пользователя оставить только записи с датой его первого действия
-- Ещё можно было бы для каждого пользователя найти дату первого действия и к ней LEFT JOIN таблицу с числом заказов по дням 
INNER JOIN (
SELECT user_id,
       MIN(time::DATE) AS date
FROM user_actions
GROUP BY user_id) t ON user_actions.user_id = t.user_id AND user_actions.time::DATE = t.date
WHERE user_actions.order_id NOT IN (SELECT * FROM canceled_orders)
GROUP BY user_actions.time::DATE) t2 USING(date)

-- Считаем orders (общее число)
LEFT JOIN (
SELECT COUNT(order_id) AS orders, 
       time::DATE AS date
FROM user_actions
WHERE order_id NOT IN (SELECT * FROM canceled_orders)
GROUP BY date) t3 USING(date)
ORDER BY date

