-- ============================================
-- 무료체험 유형별 초기 취소율 분석
-- ============================================
-- 정의: 첫 결제(subscription) 직후 다음 이벤트가 cancel인 유저 비율
-- 산식: 취소 유저 수 / 해당 유형 첫결제 유저 수 × 100
-- ============================================

WITH cancel_users AS (
    -- 첫 결제 후 다음 이벤트가 취소인 유저 추출
    SELECT 
        f.user_id,
        s.trial_type
    FROM final_ltv AS f
    LEFT JOIN subscribe_user AS s 
        ON f.user_id = s.user_id
    WHERE f.event_type = 'subscription'
      AND f.next_event_type = 'cancel'
),
type_totals AS (
    -- 무료체험 유형별 첫결제 유저 수
    SELECT 
        s.trial_type,
        COUNT(f.user_id) AS total_count
    FROM final_ltv AS f
    LEFT JOIN subscribe_user AS s 
        ON f.user_id = s.user_id
    WHERE f.event_type = 'subscription'
    GROUP BY s.trial_type
)
SELECT 
    c.trial_type,
    ROUND(100.0 * COUNT(c.user_id) / t.total_count, 2) AS cancel_rate
FROM cancel_users AS c
LEFT JOIN type_totals AS t 
    ON c.trial_type = t.trial_type
GROUP BY c.trial_type, t.total_count;