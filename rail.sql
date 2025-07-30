
-- ==========================================
-- Patterns Observed
-- ==========================================
-- 	1.	Trip Start Indicators: Usually starts with P (Departure), sometimes with W (Released).
-- 	2.	Trip End Indicators: Typically ends with D (Arrival at Destination) or Z (Actual Placement).
-- 	3.	Silent Period Gaps: Long time gaps between empty movements (like 5+ days) could mean the railcar was loaded and not present in the empty dataset.
-- 	4.	Held Events (H): A trip can contain H events, but we should flag and exclude such trips in analysis.
-- 	5.	City Shift Check: dd_loc_city change + dd_dest_city remains constant often implies movement.
-- 	6.	Trip restart: If a time gap > 24 hours and city changes, it’s a new trip.

-- ==========================================
-- -- Implementation Plan
-- ==========================================
-- We’ll break it into 4 steps:
-- 	1.	Filter & Sort Raw Data into a temp table
-- 	2.	Assign Trip IDs using logic: new trip if gap > X hours AND city changes
-- 	3.	Aggregate Trip Stats (start, end, duration)
-- 	4.	Flag & Exclude ‘Held’ Trips

-- ==========================================
-- STEP 1: FILTER AND PREPARE BASE DATA
-- ==========================================
-- Goal: Work only with empty cars (dd_le = 'E') and sort by time
-- Assumptions:
--  - fact_clm_history_rail contains event data for each railcar
--  - We'll focus on Empty cars only (dd_le = 'E')
--  - Date difference is computed using TO_DATE() subtraction

CREATE TEMP TABLE tmp_clm_empty_events AS
SELECT 
    dd_car_init,
    dd_car_no,
    dd_clm_date_time,
    dd_loc_city,
    dd_dest_city,
    dd_sight_code,
    dd_le,
    TO_DATE(dd_clm_date_time) AS clm_date,
    LAG(TO_DATE(dd_clm_date_time)) OVER (PARTITION BY dd_car_init, dd_car_no ORDER BY dd_clm_date_time) AS prev_clm_date,
    LAG(dd_loc_city) OVER (PARTITION BY dd_car_init, dd_car_no ORDER BY dd_clm_date_time) AS prev_loc_city,
    LAG(dd_sight_code) OVER (PARTITION BY dd_car_init, dd_car_no ORDER BY dd_clm_date_time) AS prev_sight_code
FROM fact_clm_history_rail
WHERE dd_le = 'E';


-- ==========================================
-- STEP 2: IDENTIFY TRIP BREAKS & ASSIGN TRIP IDS
-- ==========================================
-- Goal: Start new trip if:
--   - Time gap > 24 hrs between events AND loc_city changed
--   - OR Sight code is 'P' or 'W' (potential trip start)

CREATE TEMP TABLE tmp_clm_trips_marked AS
SELECT 
    *,
    CASE 
        WHEN prev_clm_date IS NULL THEN 1
        WHEN (clm_date - prev_clm_date) * 24 > 24 AND dd_loc_city != prev_loc_city THEN 1
        WHEN dd_sight_code IN ('P', 'W') AND dd_loc_city != prev_loc_city THEN 1
        ELSE 0
    END AS is_new_trip
FROM tmp_clm_empty_events;


-- ==========================================
-- STEP 3: ASSIGN TRIP ID BY CUMULATIVE SUM OF NEW TRIPS
-- ==========================================
-- Goal: For each car, assign sequential trip ID based on new trip flag

CREATE TEMP TABLE tmp_clm_trips_labeled AS
SELECT 
    *,
    SUM(is_new_trip) OVER (PARTITION BY dd_car_init, dd_car_no ORDER BY dd_clm_date_time ROWS UNBOUNDED PRECEDING) AS trip_id
FROM tmp_clm_trips_marked;


-- ==========================================
-- STEP 4: AGGREGATE EACH TRIP’S METADATA
-- ==========================================
-- Goal: For each (car, trip), calculate:
--    - Start/End time
--    - Duration
--    - Has Held Event (H)
--    - Start & End location

CREATE TEMP TABLE tmp_trip_summary AS
SELECT
    dd_car_init,
    dd_car_no,
    trip_id,
    MIN(clm_date) AS trip_start_time,
    MAX(clm_date) AS trip_end_time,
    MAX(clm_date) - MIN(clm_date) AS trip_duration_days,
    COUNT(CASE WHEN dd_sight_code = 'H' THEN 1 END) > 0 AS has_held_event,
    MIN(dd_loc_city) AS trip_start_city,
    MAX(dd_dest_city) AS trip_end_city
FROM tmp_clm_trips_labeled
GROUP BY dd_car_init, dd_car_no, trip_id;


-- ==========================================
-- STEP 5: FILTER OUT HELD TRIPS & CALCULATE AVERAGE DURATION
-- ==========================================
-- Goal: Remove trips with Held events and calculate average duration

SELECT
    AVG(trip_duration_days * 24) AS avg_trip_duration_hours
FROM tmp_trip_summary
WHERE has_held_event = FALSE;