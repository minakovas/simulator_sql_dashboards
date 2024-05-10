/*
Поля в результирующей таблице: 
date                     - Дата;
revenue                  - выручка за день; 
costs                    - Затраты за день (помещение + сборы заказов + выплаты курьерам);
tax                      - Сумма НДС с продажи товаров в этот день;
gross_profit             - Валовая прибыль в этот день (выручка за вычетом затрат и НДС); 
total_revenue            - Суммарная выручка на текущий день;
total_costs              - Суммарные затраты на текущий день; 
total_tax                - Суммарный НДС на текущий день; 
total_gross_profit       - Суммарная валовая прибыль на текущий день; 
gross_profit_ratio       - Доля валовой прибыли в выручке за этот день;
total_gross_profit_ratio - Доля суммарной валовой прибыли в суммарной выручке на текущий день
*/


-- Список продуктов с пониженным НДС (10% вместо 20%)
WITH products_with_tax_10 AS (
SELECT UNNEST(ARRAY[
'сахар', 'сухарики', 'сушки', 'семечки', 
'масло льняное', 'виноград', 'масло оливковое', 
'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
'овсянка', 'макароны', 'баранина', 'апельсины', 
'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины'
])
),

-- Затраты по дням (помещение + сборы заказов + выплаты курьерам);
costs_t AS (
SELECT date,
       CASE WHEN DATE_PART('month', date) = '8' THEN created_orders * 140 + delivered_orders * 150 + couriers_with_bonus * 400 + 120000
            WHEN DATE_PART('month', date) = '9' THEN created_orders * 115 + delivered_orders * 150 + couriers_with_bonus * 500 + 150000
       END AS costs       
FROM (
    SELECT date,
           SUM(delivered_orders) AS delivered_orders,
           COUNT(DISTINCT courier_id) FILTER (WHERE delivered_orders >= 5) AS couriers_with_bonus
    FROM (   
        SELECT time::DATE AS date,
               courier_id,
               COUNT(DISTINCT order_id) AS delivered_orders
        FROM courier_actions
        WHERE action = 'deliver_order'
        GROUP BY date, courier_id
    ) t
    GROUP BY date
) t1
LEFT JOIN (
    SELECT creation_time::DATE AS date, 
           COUNT(DISTINCT order_id) AS created_orders
    FROM orders
    WHERE order_id NOT IN (SELECT order_id
                           FROM user_actions
                           WHERE action = 'cancel_order')
    GROUP BY date
) t2 USING (date)
),

-- Выручка и сумма НДС по дням
revenue_and_tax_t AS (
SELECT date,
       SUM(price) AS revenue,
       SUM(tax) AS tax
FROM (
    SELECT date,
           price,
           CASE WHEN name IN (SELECT * FROM products_with_tax_10) THEN ROUND((price / 1.1) * 0.1, 2)
                ELSE ROUND((price / 1.2) * 0.2, 2)
           END AS tax
    FROM (
        SELECT creation_time::DATE AS date,
               order_id,
               UNNEST(product_ids) AS product_id
        FROM orders
        WHERE order_id NOT IN (SELECT order_id 
                               FROM user_actions
                               WHERE action = 'cancel_order')
    ) t1
    LEFT JOIN products USING(product_id)
) t2
GROUP BY date
ORDER BY date
)
-- конец CTE


SELECT date,
       revenue,
       costs,
       tax,
       revenue - costs - tax AS gross_profit,
       SUM(revenue) OVER(ORDER BY date) AS total_revenue,
       SUM(costs) OVER(ORDER BY date) AS total_costs,
       SUM(tax) OVER(ORDER BY date) AS total_tax,
       SUM(revenue - costs - tax) OVER(ORDER BY date) AS total_gross_profit,
       ROUND(((revenue - costs - tax) / revenue) * 100, 2) AS gross_profit_ratio,
       ROUND((SUM(revenue - costs - tax) OVER(ORDER BY date) / SUM(revenue) OVER(ORDER BY date)) * 100, 2) AS total_gross_profit_ratio
FROM revenue_and_tax_t
LEFT JOIN costs_t USING(date)
ORDER BY date
