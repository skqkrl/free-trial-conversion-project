-- ============================================
-- 분석 대상 유저 마스터 테이블 생성
-- ============================================
-- 목적: 무료체험 기간과 동일 기간에 가입한 유저만 추출하여
--       가입 → 체험 → 결제 순서를 준수하는 분석 대상 정의
-- 전처리:
--   1) A/B 타입 제공 기간 내 가입 유저만 추출
--   2) 중복 결제 건 정제 (최종 결제 기준 채택)
--   3) 가입 → 체험 → 결제 시간 순서 검증
-- ============================================

CREATE TABLE free_trial_filtered AS
WITH type_a AS (
    SELECT 
        MIN(DATE_ADD(client_event_time, INTERVAL 9 HOUR)) AS a_start,
        MAX(DATE_ADD(client_event_time, INTERVAL 9 HOUR)) AS a_end
    FROM start_free_trial
    WHERE trial_type = 'A'
),
type_b AS (
    SELECT
        MIN(DATE_ADD(client_event_time, INTERVAL 9 HOUR)) AS b_start,
        MAX(DATE_ADD(client_event_time, INTERVAL 9 HOUR)) AS b_end
    FROM start_free_trial
    WHERE trial_type = 'B'
),
signup AS (
    SELECT 
        s.user_id,
        DATE_ADD(s.client_event_time, INTERVAL 9 HOUR) AS signup_ts
    FROM complete_signup AS s
    CROSS JOIN type_a AS a
    CROSS JOIN type_b AS b
    WHERE (DATE_ADD(s.client_event_time, INTERVAL 9 HOUR) BETWEEN a.a_start AND a.a_end)
       OR (DATE_ADD(s.client_event_time, INTERVAL 9 HOUR) BETWEEN b.b_start AND b.b_end)
),
trial AS (
    SELECT 
        user_id, 
        MAX(DATE_ADD(client_event_time, INTERVAL 9 HOUR)) AS trial_ts, 
        MAX(trial_type) AS trial_type  
    FROM start_free_trial
    GROUP BY user_id
),
-- 중복 결제 건 정제: 동일 유저의 최종 결제 기준 채택
subscribe_ranked AS (
    SELECT 
        user_id,
        DATE_ADD(client_event_time, INTERVAL 9 HOUR) AS subscription_ts,
        paid_amount,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY client_event_time DESC) AS rn
    FROM complete_subscription
),
subscribe AS (
    SELECT 
        user_id,
        subscription_ts,
        paid_amount
    FROM subscribe_ranked
    WHERE rn = 1
)
SELECT
    s.user_id,
    t.trial_ts,
    t.trial_type,
    s.signup_ts,
    sub.subscription_ts,
    sub.paid_amount
FROM signup AS s
LEFT JOIN trial AS t
    ON s.user_id = t.user_id
LEFT JOIN subscribe AS sub
    ON s.user_id = sub.user_id
WHERE 
    -- 무료체험은 반드시 가입 이후 시작
    (t.trial_ts IS NULL OR t.trial_ts > s.signup_ts)
    -- 구독은 반드시 가입 이후
    AND (sub.subscription_ts IS NULL OR sub.subscription_ts > s.signup_ts)
    -- 구독은 무료체험 이후여야 함
    AND (t.trial_ts IS NULL OR sub.subscription_ts IS NULL OR sub.subscription_ts > t.trial_ts);
