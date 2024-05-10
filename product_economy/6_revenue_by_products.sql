/*
Расчёт долей выручки с каждого продукта
Если доля выручки с продукта < 0.5%, ставим ему категорию "ДРУГОЕ"
*/

WITH products_revenue AS (
SELECT name,
       SUM(price) AS revenue
FROM (
    SELECT UNNEST(product_ids) AS product_id
    FROM orders
    WHERE order_id NOT IN (SELECT order_id
                           FROM user_actions
                           WHERE action = 'cancel_order')
    ) t
LEFT JOIN products USING(product_id)
GROUP BY name
)


SELECT product_name,
       SUM(revenue) AS revenue,
       ROUND((SUM(revenue) / (SELECT SUM(revenue) FROM products_revenue)) * 100, 2) AS share_in_revenue
FROM (
    SELECT CASE 
           WHEN (revenue / (SELECT SUM(revenue) FROM products_revenue)) * 100 >= 0.5 THEN name
           ELSE 'ДРУГОЕ'
           END AS product_name,
           revenue
    FROM products_revenue
) t
GROUP BY product_name
ORDER BY revenue DESC
    