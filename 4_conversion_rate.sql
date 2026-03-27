-- ============================================
-- 무료체험 유형별 결제 전환율 분석
-- ============================================
-- 정의: 각 무료체험 유형(A/B/미체험)별 결제 전환 비율
-- 산식: 결제 전환자 수 / 해당 유형 전체 유저 수 × 100
-- ============================================

SELECT
    COALESCE(trial_type, 'Non-trial') AS segment,
    COUNT(DISTINCT user_id) AS total_users,
    SUM(CASE WHEN subscription_ts IS NOT NULL THEN 1 ELSE 0 END) AS converted_users,
    ROUND(100.0 * SUM(CASE WHEN subscription_ts IS NOT NULL THEN 1 ELSE 0 END) 
               / NULLIF(COUNT(*), 0), 2) AS conversion_rate
FROM free_trial_filtered
GROUP BY COALESCE(trial_type, 'Non-trial')
ORDER BY segment;
