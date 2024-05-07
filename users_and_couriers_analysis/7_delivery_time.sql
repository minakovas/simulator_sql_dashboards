/*
Подсчет среднего, минимального и максимального времени доставки заказа для каждого дня
*/

SELECT time::DATE AS date,
       ROUND(AVG(EXTRACT('epoch' FROM time - time_accept) / 60))::INTEGER AS minutes_to_deliver_avg,
       ROUND(MIN(EXTRACT('epoch' FROM time - time_accept) / 60))::INTEGER AS minutes_to_deliver_min,
       ROUND(MAX(EXTRACT('epoch' FROM time - time_accept) / 60))::INTEGER AS minutes_to_deliver_max

FROM (
SELECT time,
       action,
       LAG(time, 1) OVER(PARTITION BY courier_id, order_id ORDER BY time ASC) AS time_accept
FROM courier_actions
WHERE order_id NOT IN (SELECT order_id
                       FROM user_actions
                       WHERE action = 'cancel_order')
) t 
WHERE action = 'deliver_order'
GROUP BY date
ORDER BY date