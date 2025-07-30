/***************************************************************************************************
    STEP 1: IDENTIFY RAILCAR TRIPS AND STORE TO TEMP TABLE

    AIM:
    -----
    Identify unique EMPTY railcar trips using event patterns from the `fact_clm_history_rail` table.

    DEFINITION OF A TRIP:
    ----------------------
    A railcar trip (empty only) starts when:
      - Current sight code is 'Q' (Start of Trip) or 'P' (Departure)
      - OR Previous event was terminal: 'D' (Arrival at destination), 'Y' (Constructive Placement), 'Z' (Actual Placement)
      - OR Time gap from previous event > 24 hours

    ASSUMPTIONS:
    -------------
    - We consider only EMPTY cars (`dd_le = 'E'`)
    - Unique identifier: CONCAT(dd_car_init, dd_car_no)
    - Timestamp used: `dd_clm_date_time`
    - ROW-based functions (e.g., LAG) not available in Aera; simulated using self-join
***************************************************************************************************/

INSERT INTO tmp_trip_identified_railcar (
    railcar_id,
    dd_car_init,
    dd_car_no,
    event_time,
    current_event,
    dd_le,
    dd_loc_city,
    dd_dest_city,
    dd_dest_state,
    dd_route_code,
    dd_railroad_carrier,
    prev_event_time,
    prev_event_code,
    time_diff_hours,
    is_trip_start,
    trip_id_marker
)
SELECT 
    CONCAT(f1.dd_car_init, f1.dd_car_no) AS railcar_id,
    f1.dd_car_init,
    f1.dd_car_no,
    f1.dd_clm_date_time AS event_time,
    f1.dd_sight_code AS current_event,
    f1.dd_le,
    f1.dd_loc_city,
    f1.dd_dest_city,
    f1.dd_dest_state,
    f1.dd_route_code,
    f1.dd_railroad_carrier,

    MAX(f2.dd_clm_date_time) AS prev_event_time,
    MAX(f2.dd_sight_code) AS prev_event_code,

    ROUND((TO_DATE(f1.dd_clm_date_time) - TO_DATE(MAX(f2.dd_clm_date_time))) * 24, 2) AS time_diff_hours,

    CASE
        WHEN f1.dd_sight_code IN ('Q', 'P') THEN 1
        WHEN MAX(f2.dd_sight_code) IN ('D', 'Y', 'Z') THEN 1
        WHEN (TO_DATE(f1.dd_clm_date_time) - TO_DATE(MAX(f2.dd_clm_date_time))) * 24 > 24 THEN 1
        ELSE 0
    END AS is_trip_start,

    CASE 
        WHEN f1.dd_sight_code IN ('Q', 'P') 
             OR MAX(f2.dd_sight_code) IN ('D', 'Y', 'Z') 
             OR (TO_DATE(f1.dd_clm_date_time) - TO_DATE(MAX(f2.dd_clm_date_time))) * 24 > 24
        THEN CONCAT(CONCAT(f1.dd_car_init, f1.dd_car_no), '_', TO_CHAR(f1.dd_clm_date_time, 'YYYYMMDDHH24MISS'))
        ELSE NULL
    END AS trip_id_marker

FROM fact_clm_history_rail f1

-- Self-join to simulate prior event for the same railcar
LEFT JOIN fact_clm_history_rail f2
    ON f1.dd_car_init = f2.dd_car_init
    AND f1.dd_car_no = f2.dd_car_no
    AND TO_DATE(f2.dd_clm_date_time) < TO_DATE(f1.dd_clm_date_time)
    AND f2.dd_le = 'E'

WHERE f1.dd_le = 'E'  -- Only EMPTY railcars

GROUP BY
    f1.dd_car_init,
    f1.dd_car_no,
    f1.dd_clm_date_time,
    f1.dd_sight_code,
    f1.dd_le,
    f1.dd_loc_city,
    f1.dd_dest_city,
    f1.dd_dest_state,
    f1.dd_route_code,
    f1.dd_railroad_carrier;



/***************************************************************************************************
    STEP 2: AGGREGATE TO ONE ROW PER TRIP

    AIM:
    -----
    Generate one row per unique trip from `tmp_trip_identified_railcar`, with summary stats.

    ADDITIONAL LOGIC:
    ------------------
    - Exclude trips that contain any sight code = 'H' (Held events)
    - Exclude trips where duration = 0 hours (start time == end time)
***************************************************************************************************/

SELECT 
    trip_id_marker AS trip_id,
    railcar_id,
    MIN(event_time) AS trip_start_time,
    MAX(event_time) AS trip_end_time,

    ROUND((TO_DATE(MAX(event_time)) - TO_DATE(MIN(event_time))) * 24, 2) AS trip_duration_hours,

    MIN(dd_loc_city) AS origin_city,
    MIN(dd_dest_city) AS planned_destination_city,
    MAX(dd_dest_city) AS final_destination_city,

    MIN(current_event) AS start_event_code,
    MAX(current_event) AS end_event_code,

    COUNT(*) AS total_events_in_trip

FROM tmp_trip_identified_railcar

WHERE trip_id_marker IS NOT NULL
  AND railcar_id NOT IN (
        -- Subquery: Find any trip containing held (H) event
        SELECT DISTINCT railcar_id
        FROM tmp_trip_identified_railcar
        WHERE current_event = 'H'
    )

GROUP BY
    trip_id_marker,
    railcar_id

HAVING ROUND((TO_DATE(MAX(event_time)) - TO_DATE(MIN(event_time))) * 24, 2) > 0;



/*********************************************************************************************
    STEP 3: CALCULATE AVERAGE TRIP DURATION PER RAILCAR

    AIM:
    -----
    From valid trip records, compute average duration (in hours) for each railcar.

    CONDITIONS:
    -----------
    - Use only EMPTY railcar trips
    - Exclude trips where duration = 0 or sight code was 'H'
*********************************************************************************************/

SELECT 
    railcar_id,
    COUNT(DISTINCT trip_id_marker) AS total_trips,
    ROUND(
        AVG(
            (TO_DATE(MAX(event_time)) - TO_DATE(MIN(event_time))) * 24
        ),
        2
    ) AS avg_trip_duration_hours

FROM tmp_trip_identified_railcar

WHERE trip_id_marker IS NOT NULL
  AND current_event <> 'H'

GROUP BY 
    railcar_id;