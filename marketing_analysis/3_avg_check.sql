/*
Расчёт среднего чека пользователей, привлеченных с двух РК
*/

-- Пользователи, зарегистрировавшиеся в результате Кампании № 1
WITH campaign_1_users AS (
SELECT UNNEST(ARRAY[
8631, 8632, 8638, 8643, 8657, 8673, 8706, 8707, 8715, 8723, 8732, 8739, 8741, 
8750, 8751, 8752, 8770, 8774, 8788, 8791, 8804, 8810, 8815, 8828, 8830, 8845, 
8853, 8859, 8867, 8869, 8876, 8879, 8883, 8896, 8909, 8911, 8933, 8940, 8972, 
8976, 8988, 8990, 9002, 9004, 9009, 9019, 9020, 9035, 9036, 9061, 9069, 9071, 
9075, 9081, 9085, 9089, 9108, 9113, 9144, 9145, 9146, 9162, 9165, 9167, 9175, 
9180, 9182, 9197, 9198, 9210, 9223, 9251, 9257, 9278, 9287, 9291, 9313, 9317, 
9321, 9334, 9351, 9391, 9398, 9414, 9420, 9422, 9431, 9450, 9451, 9454, 9472, 
9476, 9478, 9491, 9494, 9505, 9512, 9518, 9524, 9526, 9528, 9531, 9535, 9550, 
9559, 9561, 9562, 9599, 9603, 9605, 9611, 9612, 9615, 9625, 9633, 9652, 9654, 
9655, 9660, 9662, 9667, 9677, 9679, 9689, 9695, 9720, 9726, 9739, 9740, 9762, 
9778, 9786, 9794, 9804, 9810, 9813, 9818, 9828, 9831, 9836, 9838, 9845, 9871, 
9887, 9891, 9896, 9897, 9916, 9945, 9960, 9963, 9965, 9968, 9971, 9993, 9998, 
9999, 10001, 10013, 10016, 10023, 10030, 10051, 10057, 10064, 10082, 10103, 
10105, 10122, 10134, 10135
])),


-- Пользователи, зарегистрировавшиеся в результате Кампании № 1
campaign_2_users AS (
SELECT UNNEST(ARRAY[
8629, 8630, 8644, 8646, 8650, 8655, 8659, 8660, 8663, 8665, 8670, 8675, 8680, 8681, 
8682, 8683, 8694, 8697, 8700, 8704, 8712, 8713, 8719, 8729, 8733, 8742, 8748, 8754, 
8771, 8794, 8795, 8798, 8803, 8805, 8806, 8812, 8814, 8825, 8827, 8838, 8849, 8851, 
8854, 8855, 8870, 8878, 8882, 8886, 8890, 8893, 8900, 8902, 8913, 8916, 8923, 8929, 
8935, 8942, 8943, 8949, 8953, 8955, 8966, 8968, 8971, 8973, 8980, 8995, 8999, 9000, 
9007, 9013, 9041, 9042, 9047, 9064, 9068, 9077, 9082, 9083, 9095, 9103, 9109, 9117, 
9123, 9127, 9131, 9137, 9140, 9149, 9161, 9179, 9181, 9183, 9185, 9190, 9196, 9203, 
9207, 9226, 9227, 9229, 9230, 9231, 9250, 9255, 9259, 9267, 9273, 9281, 9282, 9289, 
9292, 9303, 9310, 9312, 9315, 9327, 9333, 9335, 9337, 9343, 9356, 9368, 9370, 9383, 
9392, 9404, 9410, 9421, 9428, 9432, 9437, 9468, 9479, 9483, 9485, 9492, 9495, 9497, 
9498, 9500, 9510, 9527, 9529, 9530, 9538, 9539, 9545, 9557, 9558, 9560, 9564, 9567, 
9570, 9591, 9596, 9598, 9616, 9631, 9634, 9635, 9636, 9658, 9666, 9672, 9684, 9692, 
9700, 9704, 9706, 9711, 9719, 9727, 9735, 9741, 9744, 9749, 9752, 9753, 9755, 9757, 
9764, 9783, 9784, 9788, 9790, 9808, 9820, 9839, 9841, 9843, 9853, 9855, 9859, 9863, 
9877, 9879, 9880, 9882, 9883, 9885, 9901, 9904, 9908, 9910, 9912, 9920, 9929, 9930, 
9935, 9939, 9958, 9959, 9961, 9983, 10027, 10033, 10038, 10045, 10047, 10048, 10058, 
10059, 10067, 10069, 10073, 10075, 10078, 10079, 10081, 10092, 10106, 10110, 10113, 10131
])), 


-- Заказы пользователей, пришедщих с двух РК за период с 1 по 7 сентября
users_sample AS (
SELECT user_id,
       order_id,
       ads_campaign
FROM (
    SELECT user_id,
           order_id,
           time::DATE AS date,
           CASE WHEN user_id IN (SELECT * FROM campaign_1_users) THEN 1
                WHEN user_id IN (SELECT * FROM campaign_2_users) THEN 2
                ELSE 0
           END AS ads_campaign,
           COUNT(action) FILTER (WHERE action = 'cancel_order') OVER(PARTITION BY order_id) AS is_canceled
    FROM user_actions
) t1 
WHERE ads_campaign IN (1, 2) 
  AND is_canceled = 0
  AND date BETWEEN '2022-09-01' AND '2022-09-07'
),

-- Стоимости неотмененных заказов
orders_values AS (
SELECT order_id,
       SUM(price) AS order_value
FROM (
    SELECT order_id,
           UNNEST(product_ids) AS product_id
    FROM orders 
    WHERE order_id NOT IN (SELECT order_id
                           FROM user_actions
                           WHERE action = 'cancel_order')
) t3
LEFT JOIN products USING(product_id)
GROUP BY order_id
)
-- Конец CTE 
 
 
SELECT CONCAT('Кампания № ', ads_campaign) AS ads_campaign,
       ROUND(AVG(avg_check_per_user), 2) AS avg_check
FROM (
    SELECT user_id,
           ads_campaign,
           -- средний чек на пользователя
           AVG(order_value) AS avg_check_per_user
    FROM users_sample
    LEFT JOIN orders_values USING(order_id)
    GROUP BY user_id, ads_campaign
) t5 
GROUP BY ads_campaign
ORDER BY avg_check DESC 



-- Запрос ниже давал неправильный ответ. Надо сначала посчитать средний чек на каждого пользователя, а потом усреднить их средние чеки
-- Не совсем понятно, почему так, но буду иметь в виду

-- SELECT CONCAT('Кампания № ', ads_campaign) AS ads_campaign,
--       ROUND(SUM(price) / COUNT(DISTINCT order_id)::DECIMAL, 2) AS avg_order_value
-- FROM (
--     SELECT user_id,
--           order_id,
--           ads_campaign
--     FROM (
--         SELECT user_id,
--               order_id,
--               time::DATE AS date,
--               CASE WHEN user_id IN (SELECT * FROM campaign_1_users) THEN 1
--                     WHEN user_id IN (SELECT * FROM campaign_2_users) THEN 2
--                     ELSE 0
--               END AS ads_campaign,
--               COUNT(action) FILTER (WHERE action = 'cancel_order') OVER(PARTITION BY order_id) AS is_canceled
--         FROM user_actions
--     ) t1 
--     WHERE ads_campaign IN (1, 2) 
--       AND is_canceled = 0
--       AND date BETWEEN '2022-09-01' AND '2022-09-07'
-- ) t2
-- LEFT JOIN (
--     SELECT order_id,
--           UNNEST(product_ids) AS product_id
--     FROM orders 
--     WHERE order_id NOT IN (SELECT order_id
--                           FROM user_actions
--                           WHERE action = 'cancel_order')
-- ) t3 USING(order_id)
-- LEFT JOIN products USING(product_id)
-- GROUP BY ads_campaign