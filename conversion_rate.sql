SELECT
    COALESCE(trial_type, 'Non-trial') AS segment,
    COUNT(distinct(user_id)) AS total_users,
    SUM(CASE WHEN subscription_ts IS NOT NULL THEN 1 ELSE 0 END) AS converted_users,
    ROUND(100.0 * SUM(CASE WHEN subscription_ts IS NOT NULL THEN 1 ELSE 0 END) 
               / NULLIF(COUNT(*), 0), 2) AS conversion_rate
FROM free_trial_filtered
GROUP BY COALESCE(trial_type, 'Non-trial')
ORDER BY segment; 