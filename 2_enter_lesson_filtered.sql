-- ============================================
-- 결제 후 레슨 수강 유저 필터링 테이블 생성
-- ============================================
-- 목적: 첫 결제 완료 후 실제 레슨을 수강한 유저만 추출
-- 활용: 전환·유지 분석용 유저 세분화 (67,663명 → 5,002명)
-- 조건: subscription_ts 이후 레슨 수강 기록이 있는 유저만 포함
-- ============================================

CREATE TABLE enter_lesson_filtered AS
SELECT 
    e.user_id,
    f.trial_type,
    DATE_ADD(e.client_event_time, INTERVAL 9 HOUR) AS client_event_time,
    HOUR(DATE_ADD(e.client_event_time, INTERVAL 9 HOUR)) AS event_hour,
    e.content_id,
    e.lesson_id
FROM enter_lesson_page AS e
JOIN free_trial_filtered AS f
    ON e.user_id = f.user_id
WHERE f.subscription_ts IS NOT NULL
  AND DATE_ADD(e.client_event_time, INTERVAL 9 HOUR) > f.subscription_ts;
