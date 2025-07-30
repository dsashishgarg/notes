SELECT 
    dd_sight_code,
    COUNT(*) AS event_count
FROM fact_clm_history_rail
WHERE dd_car_init = 'XYZ' AND dd_car_no = '123456'
  AND dd_le = 'E'
GROUP BY dd_sight_code
ORDER BY event_count DESC;

SELECT 
    dd_car_init,
    dd_car_no,
    dd_le,
    dd_sight_code,
    dd_clm_date_time,
    dd_loc_city,
    dd_dest_city,
    dd_dest_state,
    dd_route_code,
    dd_railroad_carrier
FROM fact_clm_history_rail
WHERE dd_car_init = 'XYZ' AND dd_car_no = '123456'
  AND dd_le = 'E'
ORDER BY dd_clm_date_time ASC;

SELECT 
    dd_sight_code,
    COUNT(*) AS event_count
FROM fact_clm_history_rail
WHERE dd_le = 'E'
GROUP BY dd_sight_code
ORDER BY event_count DESC;

SELECT 
    dd_car_init,
    dd_car_no,
    dd_sight_code,
    dd_clm_date_time,
    dd_loc_city,
    dd_dest_city,
    dd_dest_state,
    dd_route_code
FROM fact_clm_history_rail
WHERE dd_le = 'E'
  AND dd_car_init = 'XYZ'
  AND dd_car_no = '123456'
ORDER BY dd_clm_date_time;