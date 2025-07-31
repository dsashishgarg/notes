/* ---------------------------------------------------------------------------------------------------
   SQL SCRIPT: Trip Segmentation and Junction Timing for Empty Railcars (fact_clm_history_rail)
   ---------------------------------------------------------------------------------------------------

   GOAL:
   -----
   To analyze empty railcar movements and compute the average time taken to reach the first junction (Sight Code = 'J').
   Additionally, we want to track supporting trip characteristics like:
     - total junctions (count of 'J')
     - if trip had any held events (Sight Code = 'H')
     - route consistency
     - trip start/end city/timestamp
     - exclude held trips from final average calculation

   FINAL OUTPUT:
   -------------
   One row per empty trip with:
     - trip ID
     - railcar ID
     - start and end timestamp
     - start and end city
     - route code
     - time to first junction
     - total junctions
     - held event flag

   ---------------------------------------------------------------------------------------------------
   PATTERNS & FINDINGS FROM EXPLORATION
   -------------------------------------
   ✅ Sight Codes:
      - 'P', 'A' are dominant (usually frequent updates or in-transit events)
      - 'D' often marks end of trip, usually at destination
      - 'W' can be seen as restart or re-initiation of trip (not always)
      - 'H' = HELD => Should NOT be used to split trips but should be flagged
      - 'J' = Junction => Track this for "first junction timing" metric

   ✅ Important Columns:
      - dd_car_init, dd_car_no => Unique Railcar
      - dd_le => Empty ('E') or Loaded ('L')
      - dd_loc_city, dd_dest_city => Key spatial markers
      - dd_clm_date_time => Event timestamp
      - dd_route_code => Generally constant within a trip, may change if rerouted

   ✅ Trip Segmentation Logic:
      - Focus on EMPTY (dd_le = 'E') railcar events only
      - Within each railcar’s ordered events:
         - A new trip starts when:
            * The destination city changes compared to the last trip
            * OR route code changes
            * OR more than X hours (e.g., 48) of inactivity between events
      - H events may pause trips for days — don't use to split, but mark trips having them

   ✅ Junction Logic:
      - Count total J events per trip
      - Calculate time from trip start to first J event (used for average time metric)

   ---------------------------------------------------------------------------------------------------
   STEP 1: FILTER EMPTY RAILCAR EVENTS
   --------------------------------------------------------------------------------------------------- */

WITH empty_events AS (
  SELECT
    *,
    CONCAT(dd_car_init, '-', dd_car_no) AS railcar_id
  FROM
    fact_clm_history_rail
  WHERE
    dd_le = 'E'
),

/* ---------------------------------------------------------------------------------------------------
   STEP 2: SORT EVENTS BY RAILCAR AND TIMESTAMP
   We emulate LAG by using GROUPED RANK() approach
--------------------------------------------------------------------------------------------------- */

ranked_events AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY railcar_id ORDER BY dd_clm_date_time) AS rn
  FROM
    empty_events
),

/* ---------------------------------------------------------------------------------------------------
   STEP 3: CREATE EVENT PAIRS TO COMPARE EACH EVENT WITH PREVIOUS EVENT
--------------------------------------------------------------------------------------------------- */

event_pairs AS (
  SELECT
    curr.railcar_id,
    curr.dd_clm_date_time AS current_time,
    curr.dd_loc_city AS current_city,
    curr.dd_dest_city AS current_dest,
    curr.dd_route_code AS current_route,
    curr.sight_code AS current_sight,
    prev.dd_clm_date_time AS prev_time,
    prev.dd_dest_city AS prev_dest,
    prev.dd_route_code AS prev_route,
    DATETIME_DIFF(curr.dd_clm_date_time, prev.dd_clm_date_time, HOUR) AS hours_diff
  FROM
    ranked_events curr
  LEFT JOIN ranked_events prev
    ON curr.railcar_id = prev.railcar_id AND curr.rn = prev.rn + 1
),

/* ---------------------------------------------------------------------------------------------------
   STEP 4: IDENTIFY TRIP BREAK POINTS
   A new trip starts when:
     - Destination city changed
     - OR route code changed
     - OR time gap > 48 hours
--------------------------------------------------------------------------------------------------- */

trip_breaks AS (
  SELECT
    *,
    CASE
      WHEN prev_time IS NULL THEN 1  -- First record for railcar
      WHEN current_dest != prev_dest THEN 1
      WHEN current_route != prev_route THEN 1
      WHEN hours_diff > 48 THEN 1
      ELSE 0
    END AS is_trip_start
  FROM
    event_pairs
),

/* ---------------------------------------------------------------------------------------------------
   STEP 5: ASSIGN TRIP IDs USING CUMULATIVE SUM OF trip_start FLAGS
--------------------------------------------------------------------------------------------------- */

trip_segments AS (
  SELECT
    *,
    CONCAT(railcar_id, '_', CAST(SUM(is_trip_start) OVER (PARTITION BY railcar_id ORDER BY current_time ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS STRING)) AS trip_id
  FROM
    trip_breaks
),

/* ---------------------------------------------------------------------------------------------------
   STEP 6: AGGREGATE TRIP DETAILS
--------------------------------------------------------------------------------------------------- */

trip_summary AS (
  SELECT
    trip_id,
    railcar_id,
    MIN(current_time) AS trip_start_time,
    MAX(current_time) AS trip_end_time,
    MIN(current_city) AS trip_start_city,
    MAX(current_dest) AS trip_end_dest,
    MAX(current_route) AS route_code,
    COUNTIF(current_sight = 'J') AS junction_count,
    MIN(CASE WHEN current_sight = 'J' THEN current_time ELSE NULL END) AS first_junction_time,
    MAX(CASE WHEN current_sight = 'H' THEN 1 ELSE 0 END) AS has_held_flag
  FROM
    trip_segments
  GROUP BY
    trip_id, railcar_id
),

/* ---------------------------------------------------------------------------------------------------
   STEP 7: FINAL OUTPUT – CALCULATE TIME TO FIRST JUNCTION
--------------------------------------------------------------------------------------------------- */

final_trips AS (
  SELECT
    *,
    DATETIME_DIFF(first_junction_time, trip_start_time, HOUR) AS time_to_first_junction_hrs
  FROM
    trip_summary
)

-- ---------------------------------------------------------------------------------------------------
-- FINAL SELECT
-- ---------------------------------------------------------------------------------------------------

SELECT
  trip_id,
  railcar_id,
  trip_start_time,
  trip_end_time,
  trip_start_city,
  trip_end_dest,
  route_code,
  junction_count,
  time_to_first_junction_hrs,
  has_held_flag
FROM
  final_trips;