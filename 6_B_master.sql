-- ============================================
-- B타입 체험군 마스터 테이블 생성
-- ============================================
-- 목적: B타입 무료체험 유저의 체험 기간 중 레슨 수강 데이터를 구조화
-- 산출 흐름: B타입 유저 추출 → 결제 전 레슨 로그 결합 → 체험 기간 내 레슨만 필터링
-- 활용: 취소 유저 vs 유지 유저의 체험 기간 중 학습 패턴 비교 분석
-- ============================================


-- [Step 1] B타입 유저의 결제 전 레슨 로그 추출
-- ============================================
-- retention_master에서 B타입 유저만 추출한 뒤,
-- 첫 결제(subscription_ts) 이전의 레슨 수강 기록을 결합
-- * 레슨 기록이 없는 유저도 포함 (RIGHT JOIN)
-- ============================================

CREATE TABLE b_user_lesson AS
WITH b_user_base AS (
    SELECT 
        user_id, 
        trial_type, 
        subscription_ts 
    FROM retention_master
    WHERE trial_type = 'B'
    GROUP BY user_id, trial_type, subscription_ts
),
lesson_log AS (
    SELECT 
        user_id, 
        DATE_ADD(client_event_time, INTERVAL 9 HOUR) AS lesson_ts, 
        content_id, 
        lesson_id
    FROM enter_lesson_page
)
SELECT 
    u.user_id, 
    u.trial_type, 
    u.subscription_ts, 
    e.lesson_ts, 
    e.content_id, 
    e.lesson_id
FROM b_user_base AS u
LEFT JOIN lesson_log AS e 
    ON u.user_id = e.user_id
WHERE e.lesson_ts < u.subscription_ts 
   OR e.user_id IS NULL;


-- [Step 2] B타입 마스터 테이블 생성
-- ============================================
-- Step 1 결과에 무료체험 시작 시점(trial_ts)을 결합하여
-- 체험 기간(trial_ts ~ subscription_ts) 내 레슨만 필터링
-- * 체험 기간 중 학습 행동이 있어야 과몰입 여부 판단 가능
-- * 레슨 기록이 없는 유저도 포함 (분모 유지 목적)
-- ============================================

CREATE TABLE b_master AS
WITH b_trial_ts AS (
    SELECT 
        user_id, 
        trial_ts 
    FROM free_trial_filtered
    WHERE trial_type = 'B'
)
SELECT 
    p.user_id, 
    p.trial_type, 
    t.trial_ts, 
    p.lesson_ts, 
    p.subscription_ts, 
    p.content_id, 
    p.lesson_id
FROM b_user_lesson AS p
LEFT JOIN b_trial_ts AS t 
    ON p.user_id = t.user_id
WHERE (t.trial_ts < p.lesson_ts AND t.trial_ts < p.subscription_ts)
   OR t.user_id IS NULL;
