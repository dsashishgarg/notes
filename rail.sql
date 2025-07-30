
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
-- STEP 1: FILTER EMPTY EVENTS & ADD ROW NUMBERS
-- ==========================================
CREATE TEMP TABLE tmp_empty_events AS
SELECT
    dd_car_init,
    dd_car_no,
    dd_clm_date_time,
    dd_loc_city,
    dd_dest_city,
    dd_sight_code,
    dd_le
FROM fact_clm_history_rail
WHERE dd_le = 'E';

-- Add row numbers to simulate ordering
CREATE TEMP TABLE tmp_empty_events_rn AS
SELECT 
    t1.*,
    ROW_NUMBER() OVER (ORDER BY dd_car_init, dd_car_no, dd_clm_date_time) AS rn
FROM tmp_empty_events t1;

-- ==========================================
-- STEP 2: SELF JOIN TO SIMULATE LAG()
-- ==========================================
CREATE TEMP TABLE tmp_events_with_prev AS
SELECT
    curr.dd_car_init,
    curr.dd_car_no,
    curr.dd_clm_date_time,
    curr.dd_loc_city,
    curr.dd_dest_city,
    curr.dd_sight_code,
    curr.dd_le,
    prev.dd_clm_date_time AS prev_clm_date_time,
    prev.dd_loc_city AS prev_loc_city
FROM tmp_empty_events_rn curr
LEFT JOIN tmp_empty_events_rn prev
  ON curr.dd_car_init = prev.dd_car_init
 AND curr.dd_car_no = prev.dd_car_no
 AND curr.rn = prev.rn + 1;

-- ==========================================
-- STEP 3: DETECT TRIP BREAKS
-- ==========================================
CREATE TEMP TABLE tmp_trip_flags AS
SELECT
    dd_car_init,
    dd_car_no,
    dd_clm_date_time,
    dd_loc_city,
    dd_dest_city,
    dd_sight_code,
    CASE
        WHEN prev_clm_date_time IS NULL THEN 1
        WHEN (TO_DATE(dd_clm_date_time) - TO_DATE(prev_clm_date_time)) * 24 > 24 
             AND dd_loc_city <> prev_loc_city THEN 1
        WHEN dd_sight_code IN ('P', 'W') AND dd_loc_city <> prev_loc_city THEN 1
        ELSE 0
    END AS is_new_trip
FROM tmp_events_with_prev;

-- ==========================================
-- STEP 4: ASSIGN TRIP IDs (MANUAL RUNNING COUNT)
-- ==========================================
-- Aera does not support SUM OVER() — we simulate it manually outside SQL or assign post-processing.
-- So instead, just export trip break markers and process trip IDs later if needed.

-- ==========================================
-- STEP 5: AGGREGATE TRIP DATA
-- ==========================================
-- Aggregate to get trip start/end, duration, held-event flag

CREATE TEMP TABLE tmp_trip_staging AS
SELECT
    dd_car_init,
    dd_car_no,
    dd_loc_city,
    dd_dest_city,
    MIN(TO_DATE(dd_clm_date_time)) AS trip_start_time,
    MAX(TO_DATE(dd_clm_date_time)) AS trip_end_time,
    MAX(TO_DATE(dd_clm_date_time)) - MIN(TO_DATE(dd_clm_date_time)) AS trip_duration_days,
    COUNT(CASE WHEN dd_sight_code = 'H' THEN 1 ELSE NULL END) AS held_event_count
FROM tmp_empty_events
GROUP BY dd_car_init, dd_car_no, dd_loc_city, dd_dest_city;

-- ==========================================
-- STEP 6: FILTER OUT TRIPS WITH HELD EVENTS
-- ==========================================
SELECT 
    *,
    trip_duration_days * 24 AS trip_duration_hours
FROM tmp_trip_staging
WHERE held_event_count = 0;