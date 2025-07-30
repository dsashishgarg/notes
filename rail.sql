/***************************************************************************************************
    STEP 1: IDENTIFY RAILCAR TRIPS AND STORE TO TEMP TABLE

    AIM:
    -----
    Identify unique EMPTY railcar trips using event patterns from the `fact_clm_history_rail` table.

    A railcar trip is defined as a sequence of EMPTY railcar movements, beginning when:
      - Sight code is 'Q' (Start of Trip) or 'P' (Departure)
      - OR Previous event is a terminal code ('D', 'Z', 'Y')
      - OR More than 24 hours gap since previous event

    ASSUMPTIONS:
    -------------
    - Only EMPTY cars (dd_le = 'E') are considered
    - Held/Delayed events (sight_code = 'H') are excluded from logic
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

    -- Previous event details
    MAX(f2.dd_clm_date_time) AS prev_event_time,
    MAX(f2.dd_sight_code) AS prev_event_code,

    ROUND(
        (TO_DATE(f1.dd_clm_date_time) - TO_DATE(MAX(f2.dd_clm_date_time))) * 24,
        2
    ) AS time_diff_hours,

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
        THEN CONCAT(
            CONCAT(f1.dd_car_init, f1.dd_car_no),
            '_',
            TO_CHAR(f1.dd_clm_date_time, 'YYYYMMDDHH24MISS')
        )
        ELSE NULL
    END AS trip_id_marker

FROM fact_clm_history_rail f1

-- Self-join to simulate previous row
LEFT JOIN fact_clm_history_rail f2
    ON f1.dd_car_init = f2.dd_car_init
    AND f1.dd_car_no = f2.dd_car_no
    AND TO_DATE(f2.dd_clm_date_time) < TO_DATE(f1.dd_clm_date_time)
    AND f2.dd_le = 'E'
    AND f2.dd_sight_code != 'H'  -- Exclude 'H' from previous event check

-- Only keep non-held, empty events
WHERE f1.dd_le = 'E'
  AND f1.dd_sight_code != 'H'

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
    STEP 2: TRIP SUMMARY

    Description:
    ------------
    Aggregate all events within a trip to calculate:
      - Start/End timestamps
      - Duration in hours
      - Locations
      - Number of events in trip

    Assumption:
    ------------
    - Held events ('H') have already been filtered out
***************************************************************************************************/

SELECT 
    trip_id_marker AS trip_id,
    railcar_id,

    MIN(event_time) AS trip_start_time,
    MAX(event_time) AS trip_end_time,

    ROUND(
        (TO_DATE(MAX(event_time)) - TO_DATE(MIN(event_time))) * 24,
        2
    ) AS trip_duration_hours,

    MIN(dd_loc_city) AS origin_city,
    MIN(dd_dest_city) AS planned_destination_city,
    MAX(dd_dest_city) AS final_destination_city,

    MIN(current_event) AS start_event_code,
    MAX(current_event) AS end_event_code,

    COUNT(*) AS total_events_in_trip

FROM tmp_trip_identified_railcar

WHERE trip_id_marker IS NOT NULL

GROUP BY
    trip_id_marker,
    railcar_id
HAVING ROUND(
    (TO_DATE(MAX(event_time)) - TO_DATE(MIN(event_time))) * 24,
    2
) > 0;

/***************************************************************************************************
    STEP 3: AVERAGE TRIP DURATION PER RAILCAR

    Description:
    ------------
    Compute average duration of EMPTY railcar trips (excluding 'H' events and zero-duration trips)

***************************************************************************************************/

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

GROUP BY 
    railcar_id
HAVING AVG(
    (TO_DATE(MAX(event_time)) - TO_DATE(MIN(event_time))) * 24
) > 0;