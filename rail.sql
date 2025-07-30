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
    - Data source: `fact_clm_history_rail`
    - We only consider `dd_le = 'E'` (EMPTY cars)
    - Sight code defines event type
    - Timestamp used: `dd_clm_date_time`
    - Unique railcar ID is `dd_car_init || dd_car_no`

***************************************************************************************************/

-- Store trip-identified data into a temporary table
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
    -- Unique railcar ID
    CONCAT(f1.dd_car_init, f1.dd_car_no) AS railcar_id,

    -- Raw fields for traceability
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

    -- Most recent earlier event for the same car (simulating LAG using self join)
    MAX(f2.dd_clm_date_time) AS prev_event_time,
    MAX(f2.dd_sight_code) AS prev_event_code,

    -- Time difference between current and previous event in hours
    ROUND(
        (TO_DATE(f1.dd_clm_date_time) - TO_DATE(MAX(f2.dd_clm_date_time))) * 24,
        2
    ) AS time_diff_hours,

    -- Flag for trip start based on event type or time gap
    CASE
        WHEN f1.dd_sight_code IN ('Q', 'P') THEN 1
        WHEN MAX(f2.dd_sight_code) IN ('D', 'Y', 'Z') THEN 1
        WHEN (TO_DATE(f1.dd_clm_date_time) - TO_DATE(MAX(f2.dd_clm_date_time))) * 24 > 24 THEN 1
        ELSE 0
    END AS is_trip_start,

    -- Assign unique trip ID as combination of railcar and current event time
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

-- Self-join to simulate previous row logic
LEFT JOIN fact_clm_history_rail f2
    ON f1.dd_car_init = f2.dd_car_init
    AND f1.dd_car_no = f2.dd_car_no
    AND TO_DATE(f2.dd_clm_date_time) < TO_DATE(f1.dd_clm_date_time)
    AND f2.dd_le = 'E'

-- Only consider EMPTY car events in the main table
WHERE f1.dd_le = 'E'

-- Required for MAX aggregate logic in self-join
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
    From `tmp_trip_identified_railcar`, group data by each unique trip and extract:
      - Railcar ID
      - Trip ID
      - Start and End Time
      - Duration (hours)
      - Start and End Locations
      - Number of events during the trip

***************************************************************************************************/

SELECT 
    trip_id_marker AS trip_id,
    railcar_id,
    
    -- Trip start and end timestamps
    MIN(event_time) AS trip_start_time,
    MAX(event_time) AS trip_end_time,

    -- Duration in hours
    ROUND(
        (TO_DATE(MAX(event_time)) - TO_DATE(MIN(event_time))) * 24,
        2
    ) AS trip_duration_hours,

    -- First and last known locations (based on MIN/MAX time)
    MIN(dd_loc_city) AS origin_city,
    MIN(dd_dest_city) AS planned_destination_city,
    MAX(dd_dest_city) AS final_destination_city,

    -- Sight codes at trip start and end
    MIN(current_event) AS start_event_code,
    MAX(current_event) AS end_event_code,

    COUNT(*) AS total_events_in_trip

FROM tmp_trip_identified_railcar

-- Filter to keep only rows that have trip_id assigned (trip start identified)
WHERE trip_id_marker IS NOT NULL

GROUP BY
    trip_id_marker,
    railcar_id;

/*********************************************************************************************
    STEP 3: CALCULATE AVERAGE TRIP DURATION PER RAILCAR

    AIM:
    -----
    From the trip-level data in `tmp_trip_identified_railcar`, calculate the average 
    duration of trips for each unique railcar (EMPTY cars only).
    
    ASSUMPTIONS:
    -------------
    - Trip duration is calculated as MAX(event_time) - MIN(event_time)
    - Input comes from the same temporary table created earlier

*********************************************************************************************/

SELECT 
    railcar_id,

    -- Total trips completed
    COUNT(DISTINCT trip_id_marker) AS total_trips,

    -- Average duration in hours
    ROUND(
        AVG(
            (TO_DATE(MAX(event_time)) - TO_DATE(MIN(event_time))) * 24
        ),
        2
    ) AS avg_trip_duration_hours

FROM tmp_trip_identified_railcar

-- Only include events that are part of a valid trip
WHERE trip_id_marker IS NOT NULL

GROUP BY 
    railcar_id;