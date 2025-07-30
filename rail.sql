/*********************************************************************************************
    AIM:
    -----
    Identify and assign unique trip IDs to each EMPTY railcar's journey based on movement
    events logged in the `fact_clm_history_rail` table.

    Each trip is defined as a movement segment where:
    - A railcar (identified by dd_car_init + dd_car_no) begins moving from a location,
    - Ends at a destination or actual placement, or is idle for more than 24 hours.

    ===========================================================================================
    ASSUMPTIONS:
    ------------
    1. Table used: fact_clm_history_rail
    2. We are only interested in EMPTY railcars: dd_le = 'E'
    3. Railcar is uniquely identified using dd_car_init || dd_car_no
    4. Events are ordered by dd_clm_date_time
    5. A trip starts when:
       - Event sight code is 'Q' (Start of Trip) or 'P' (Departure)
       - OR Previous event is 'D' (Arrived), 'Z' (Placed), or 'Y' (Constructive Placement)
       - OR Time gap since previous event is greater than 24 hours
    6. A trip ID is assigned by cumulatively counting such start markers within each railcar
    ===========================================================================================

    PSEUDOCODE LOGIC:
    ------------------
    For each record (per railcar in time order):
        1. Compute time since previous event in hours
        2. Identify trip start conditions:
            - Current event is 'Q' or 'P'
            - Previous event is 'D', 'Z', or 'Y'
            - Time since previous > 24 hours
        3. Flag trip start with `is_new_trip = 1`
        4. Use running SUM over is_new_trip to assign incremental trip_id
**********************************************************************************************/

SELECT 
    -- Unique identifier for railcar (e.g., GATX123456)
    main.railcar_id,

    -- Core fields for event and location
    main.dd_car_init,
    main.dd_car_no,
    main.dd_clm_date_time,
    main.dd_sight_code,
    main.dd_loc_city,
    main.dd_dest_city,
    main.dd_dest_state,
    main.dd_route_code,
    main.dd_railroad_carrier,

    -- Previous event's details
    main.prev_event_time,
    main.prev_event_code,

    -- Time gap since previous event in hours
    main.hours_since_prev,

    -- Flag indicating start of a new trip
    main.is_new_trip,

    -- Unique Trip ID (incremented whenever a new trip starts)
    SUM(main.is_new_trip) 
        OVER (PARTITION BY main.railcar_id ORDER BY main.dd_clm_date_time ROWS UNBOUNDED PRECEDING) 
        AS trip_id

FROM (
    SELECT 
        -- Construct unique railcar identifier
        CONCAT(dd_car_init, dd_car_no) AS railcar_id,
        dd_car_init,
        dd_car_no,
        dd_clm_date_time,
        dd_sight_code,
        dd_le,
        dd_loc_city,
        dd_dest_city,
        dd_dest_state,
        dd_route_code,
        dd_railroad_carrier,

        -- Previous event timestamp
        LAG(dd_clm_date_time) OVER (
            PARTITION BY dd_car_init, dd_car_no 
            ORDER BY dd_clm_date_time
        ) AS prev_event_time,

        -- Previous sighting code
        LAG(dd_sight_code) OVER (
            PARTITION BY dd_car_init, dd_car_no 
            ORDER BY dd_clm_date_time
        ) AS prev_event_code,

        -- Time difference in hours between current and previous event
        ROUND(
            EXTRACT(EPOCH FROM dd_clm_date_time - 
                LAG(dd_clm_date_time) OVER (
                    PARTITION BY dd_car_init, dd_car_no 
                    ORDER BY dd_clm_date_time)
            ) / 3600, 
        2) AS hours_since_prev,

        /******************************************************
            TRIP START LOGIC:
            ------------------
            Mark current row as a new trip if:
            - Current sighting code = 'Q' (Start of Trip) or 'P' (Departure)
            - OR previous sighting code = 'D', 'Z', or 'Y'
            - OR time since last event > 24 hours
        ******************************************************/
        CASE 
            WHEN dd_sight_code IN ('Q', 'P') THEN 1
            WHEN LAG(dd_sight_code) OVER (
                PARTITION BY dd_car_init, dd_car_no 
                ORDER BY dd_clm_date_time
            ) IN ('D', 'Z', 'Y') THEN 1
            WHEN ROUND(
                EXTRACT(EPOCH FROM dd_clm_date_time - 
                    LAG(dd_clm_date_time) OVER (
                        PARTITION BY dd_car_init, dd_car_no 
                        ORDER BY dd_clm_date_time)
                ) / 3600, 
            2) > 24 THEN 1
            ELSE 0
        END AS is_new_trip

    FROM fact_clm_history_rail

    -- Filter to include only empty railcars
    WHERE dd_le = 'E'

) AS main

-- Sort output to trace movement per railcar in time order
ORDER BY main.railcar_id, main.dd_clm_date_time;

/*********************************************************************************************
--  What You Get:

-- Each row will now include:
-- 	•	trip_id: Unique numeric ID for each empty trip
-- 	•	is_new_trip: 1 if this row marks a trip start, else 0
-- 	•	Time gap between events to understand pacing
-- 	•	Original railcar event details
*********************************************************************************************/