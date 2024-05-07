/*
Подсчет числа успешных (доставленных) и отмененных заказов, 
а также cancel_rate (доля отмененных заказов среди всех оформленных) для каждого часа в сутках
*/

SELECT hour,
       successful_orders,
       canceled_orders,
       ROUND(canceled_orders / total_orders::DECIMAL, 3) AS cancel_rate
FROM (
SELECT DATE_PART('hours', creation_time)::INTEGER AS hour,
       COUNT(DISTINCT order_id) FILTER (WHERE order_id IN (SELECT order_id 
                                                           FROM user_actions
                                                           WHERE action = 'cancel_order')) AS canceled_orders,    
       COUNT(DISTINCT order_id) FILTER (WHERE order_id IN (SELECT order_id
                                                           FROM courier_actions
                                                           WHERE action = 'deliver_order')) AS successful_orders,
       COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY hour) t
ORDER BY hour
