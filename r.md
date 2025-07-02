FACT_ORDERS_AGGREGATED_EURO_AS_IS
    |
    +--> DIM_LANE_ELIGIBILITY_RAIL
    +--> DIM_STORAGE_SITE_ELIGIBILITY_EMPTY_RAIL
    +--> DIM_LANE_ELIGIBILITY_RAIL
         |
         v
    tmp_Order_Table (duplicates removed)
         |
         +--> FACT_TRIP_RAIL ----------------------------> tmp_Cal_Route
         +--> tmp_tempt_tt
                   |
                   +--> FACT_ORDERS_AGGREGATED_EURO_AS_IS
                   |
                   v
             tmp_Cal_Transittime
                     |
                     +--> tmp_od_empty_transit
                              |
                              +--> tmp_empty_lanes
                                     |
                                     +--> MP_ORDER_TABLE
                                     +--> DIM_LOCATION_RAIL
                              |
                              +--> DIM_ROUTE_RAIL
                     |
                     v
               tmp_transit_time_combined (merged from transit + od_empty)
                     |
                     +--> inserted manually (script)

FACT_LOADED_TRANSPORT_COSTS_RAIL --> tmp_transport_costs_lanes
                                          |
                                          +--> tmp_Cal_Route
                                          +--> inserted manually

tmp_Load
    |
    +--> tmp_Order_Table
    +--> DIM_LOCATION_RAIL

tmp_TVRO_Weight_restrictions
    |
    +--> tmp_tempt_tt
    +--> DIM_TVRO_RAIL
    +--> inserted manually

tmp_FACT_LANES_MASTER1
    |
    +--> tmp_transport_costs_lanes_without_duplicates
    +--> tmp_Order_Table
    +--> tmp_route_code_final
    +--> tmp_tempt_tt
    +--> tmp_transit_time_combined
    +--> tmp_Load
    +--> tmp_TVRO_Weight_restrictions

tmp_filtering_lanes_master1
    |
    +--> tmp_FACT_LANES_MASTER1
    +--> DIM_LOCATION_RAIL

tmp_filtering_lanes_master2
    |
    +--> tmp_filtering_lanes_master1
    +--> DIM_LOCATION_RAIL
    +--> DIM_ELIGIBLE_BUSINESS_GROUPS_RAIL

tmp_filtering_lanes_master3
    |
    +--> tmp_filtering_lanes_master2
    +--> DIM_LOCATION_RAIL
    +--> DIM_STORAGE_MASTER

tmp_filtering_lanes_master4
    |
    +--> tmp_filtering_lanes_master3
    +--> DIM_LOCATION_RAIL
    +--> DIM_STORAGE_MASTER
    +--> DIM_STORAGE_SITES_PARENT_DAUGHTER_MAPPING

tmp_filtering_lanes_master4 --> FACT_LANES_MASTER1

FACT_LANES_MASTER1
    |
    +--> AVG_RATE
           |
           +--> AYX_LANE_MASTER_ADP
           +--> FACT_LANES_MASTER1