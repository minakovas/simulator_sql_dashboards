/*
Расчёт Retention по всем пользователям в разбивке по дате регистрации (первой активности)
*/

SELECT date, 
       start_date,
       date - start_date AS day_number,
       DATE_TRUNC('month', start_date) AS start_month,
       DATE_TRUNC('month', date) AS month,
       COUNT(DISTINCT user_id) AS active_users,
       MAX(COUNT(DISTINCT user_id)) OVER(PARTITION BY start_date) AS first_day_users,
       ROUND((COUNT(DISTINCT user_id)::DECIMAL / MAX(COUNT(DISTINCT user_id)) OVER(PARTITION BY start_date)) * 100, 2) AS retention,
FROM (
    SELECT user_id, 
           MIN(time::DATE) OVER (PARTITION BY user_id) AS start_date,
           time::DATE AS date
    FROM user_actions
) t
GROUP BY date, start_date
ORDER BY date, start_date
