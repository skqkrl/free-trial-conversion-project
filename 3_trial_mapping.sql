-- ============================================
-- 무료체험 미체험 유저(nonA / nonB) 매핑
-- ============================================
-- 무료체험 기록이 없는 유저(trial_type IS NULL)를
-- 가입일 기준으로 해당 체험 제공 기간에 매핑
--   A타입 제공기간: 2022.01.01 ~ 2022.11.13
--   B타입 제공기간: 2023.02.01 ~ 2023.04.30
-- ============================================
UPDATE free_trial_filtered
SET trial_type = CASE
    WHEN DATE(signup_ts) BETWEEN '2022-01-01' AND '2022-11-13' THEN 'non A'
    WHEN DATE(signup_ts) BETWEEN '2023-02-01' AND '2023-04-30' THEN 'non B'
    ELSE trial_type
END
WHERE trial_type IS NULL;