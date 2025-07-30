SELECT 
    dd_car_init || dd_car_no AS railcar_id,
    dd_clm_date_time,
    dd_sight_code,
    dd_loc_city,
    dd_dest_city,
    LAG(dd_loc_city) OVER (PARTITION BY dd_car_init, dd_car_no ORDER BY dd_clm_date_time) AS prev_city
FROM fact_clm_history_rail
WHERE dd_le = 'E'
  AND dd_car_init = 'XYZ' AND dd_car_no = '123456'
ORDER BY dd_clm_date_time;


SELECT 
    dd_sight_code,
    COUNT(*) AS occurrences,
    AVG(LEAD(TO_DATE(dd_clm_date_time)) - TO_DATE(dd_clm_date_time)) * 24 AS avg_hour_gap_to_next_event
FROM (
    SELECT * FROM fact_clm_history_rail WHERE dd_le = 'E'
)
WINDOW win AS (PARTITION BY dd_car_init, dd_car_no ORDER BY dd_clm_date_time)
GROUP BY dd_sight_code
ORDER BY avg_hour_gap_to_next_event DESC;

SELECT 
    dd_sight_code,
    COUNT(*) AS count,
    dd_loc_city,
    dd_dest_city
FROM fact_clm_history_rail
WHERE dd_le = 'E'
  AND dd_sight_code = 'H'
GROUP BY dd_sight_code, dd_loc_city, dd_dest_city
ORDER BY count DESC;