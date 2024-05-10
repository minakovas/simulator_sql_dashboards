/*
В этом запросе считаются:
Выручка, полученную в этот день.
Суммарная выручку на текущий день.
Прирост выручки, полученной в этот день, относительно значения выручки за предыдущий день.
*/

SELECT date,
       revenue,
       total_revenue,
       ROUND(((revenue - prev_day_revenue) / prev_day_revenue::DECIMAL) * 100, 2) AS revenue_change
FROM (
SELECT date,
       revenue,
       SUM(revenue) OVER(ORDER BY date ASC) AS total_revenue,
       LAG(revenue, 1) OVER(ORDER BY date ASC) AS prev_day_revenue
FROM (
    SELECT unnested_orders_t.date,
           SUM(products.price) AS revenue
    FROM ( 
        SELECT order_id,
               creation_time::DATE AS date,
               product_ids,
               UNNEST(product_ids) AS product_id
        FROM orders
        WHERE order_id NOT IN (SELECT order_id
                               FROM user_actions
                               WHERE action = 'cancel_order')
    ) unnested_orders_t
    LEFT JOIN products USING(product_id)
    GROUP BY unnested_orders_t.date
) daily_revenue_t
) t
ORDER BY date
