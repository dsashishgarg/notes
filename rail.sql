/***********************************************************************************************
    AIM:
    -----
    Identify and assign unique trip IDs for each EMPTY railcar movement segment using the 
    `fact_clm_history_rail` table in Aera Decision Cloud.

    Each trip is defined as a movement sequence that begins when a railcar starts a journey 
    and ends when it is delivered, placed, or remains idle for more than 24 hours.

    =============================================================================================
    ASSUMPTIONS:
    ------------
    1. Data Source: `fact_clm_history_rail`
    2. Focus only on EMPTY railcars: `dd_le = 'E'`
    3. A railcar is uniquely identified using: `dd_car_init || dd_car_no`
    4. Events are timestamped using `dd_clm_date_time`
    5. A new trip starts when:
        - Current sight code is 'Q' (Start of Trip) or 'P' (Departure)
        - OR previous sight code is 'D', 'Z', or 'Y' (trip-end markers)
        - OR time gap from previous event > 24 hours
    6. A trip ID is derived from `railcar_id + trip_start_timestamp`
    =============================================================================================

    PSEUDOCODE LOGIC:
    ------------------
    For each row (ordered by railcar_id, event time):
        1. Join railcar to itself to simulate "previous" event
        2. Get the most recent earlier event (MAX previous date)
        3. Calculate time difference in hours: (curr_time - prev_time) * 24
        4. Identify trip start:
            - if sight code = Q/P
            - or previous sight code = D/Z/Y
            - or time gap > 24 hours
        5. Build a trip_id using: CONCAT(railcar_id, trip_start_time)
************************************************************************************************/

SELECT 
    -- 🚂 Unique Railcar ID
    CONCAT(f1.dd_car_init, f1.dd_car_no) AS railcar_id,

    -- 📅 Event details
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

    -- ⏪ Previous event timestamp and code (via self join)
    MAX(f2.dd_clm_date_time) AS prev_event_time,
    MAX(f2.dd_sight_code) AS prev_event_code,

    -- ⏱ Time gap in hours using timestamp subtraction (works in Aera)
    ROUND(
        (TO_DATE(f1.dd_clm_date_time) - TO_DATE(MAX(f2.dd_clm_date_time))) * 24,
        2
    ) AS time_diff_hours,

    -- 🚩 Trip start logic:
    -- 1 if: current event is Q/P, or previous is D/Y/Z, or time gap > 24
    CASE
        WHEN f1.dd_sight_code IN ('Q', 'P') THEN 1
        WHEN MAX(f2.dd_sight_code) IN ('D', 'Y', 'Z') THEN 1
        WHEN (TO_DATE(f1.dd_clm_date_time) - TO_DATE(MAX(f2.dd_clm_date_time))) * 24 > 24 THEN 1
        ELSE 0
    END AS is_trip_start,

    -- 🆔 Derived Trip ID using timestamp of trip start
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

-- 🧠 Self-join to simulate LAG: get last earlier event for same railcar
LEFT JOIN fact_clm_history_rail f2
    ON f1.dd_car_init = f2.dd_car_init
    AND f1.dd_car_no = f2.dd_car_no
    AND TO_DATE(f2.dd_clm_date_time) < TO_DATE(f1.dd_clm_date_time)
    AND f2.dd_le = 'E'  -- Only compare empty car events

-- 🧹 Only keep EMPTY car events for main record too
WHERE f1.dd_le = 'E'

-- 📦 Grouping required for MAX() functions on f2 values
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
    f1.dd_railroad_carrier

ORDER BY
    railcar_id,
    event_time;