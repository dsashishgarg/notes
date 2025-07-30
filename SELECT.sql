✅ Observed Patterns from Sight Code Sequences

1. Trips Often Start with Sight Code W
	•	W = RELEASED
	•	This is commonly the first event in many railcar journeys.
	•	Indicates that the car has been released for movement (could be customer release or yard release).

Insight: W can be a good starting point for a trip—but not all trips start with W.

⸻

2. Frequent Sequences: P → A Repeats
	•	P = DEPARTURE and A = ARRIVAL AT INTRANSIT RAIL LOCATION
	•	These repeat as the railcar moves from one point to another.
	•	Each P → A likely represents movement between cities or rail points.

Insight: A trip may contain many P/A pairs, showing movement along a route.

⸻

3. Trip Ends Often Include D, Z, Y
	•	D = ARRIVAL AT DESTINATION
‣ Sometimes dd_loc_city == dd_dest_city, suggesting true arrival
	•	Z = ACTUAL PLACEMENT
‣ Final placement of car at customer location
	•	Y = CONSTRUCTIVE PLACEMENT / NOTIFICATION
‣ Car available to customer, but not physically placed

Insight: These codes are strong indicators of trip completion.

⸻

4. In Some Trips, First Event is P
	•	Not all trips start with W
	•	Some begin directly with a P, especially in cases where earlier records are missing or occurred before the filtering window.

Insight: P can also be a trip start, especially if preceded by no prior W, Z, or D.