CREATE TABLE enter_lesson_filtered AS 
(
	SELECT e.user_id AS user_id,
			f.trial_type AS trial_type,
			DATE_ADD(client_event_time, INTERVAL 9 HOUR) client_event_time,
			HOUR(DATE_ADD(client_event_time, INTERVAL 9 HOUR)) event_hour,
            content_id,
            lesson_id
	FROM enter_lesson_page e
	JOIN free_trial_filtered f
	  ON e.user_id = f.user_id
	WHERE f.subscription_ts IS NOT NULL
	  AND DATE_ADD(client_event_time, INTERVAL 9 HOUR) > f.subscription_ts
)