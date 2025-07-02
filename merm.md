flowchart LR

%% Define column groupings (pseudo-tiering)
subgraph T1 [📦 Source Tables]
    direction TB
    FACT_ORDERS_AGGREGATED_EURO_AS
    FACT_ORDERS_AGGREGATED_EURO_AS_IS
    FACT_ANTICIPATED_DEMAND_RAIL
    FACT_LANES_MASTER1
    FACT_TRIP_RAIL
    FACT_LOADED_TRANSPORT_COSTS_RAIL

    DIM_LOCATION_RAIL
    DIM_STORAGE_SITES_PARENT_DAUGHTER_MAPPING
    DIM_LANE_ELIGIBILITY_RAIL
    DIM_STORAGE_SITE_ELIGIBILITY_EMPTY_RAIL
    DIM_ROUTE_RAIL
    DIM_TVRO_RAIL
    DIM_ELIGIBLE_BUSINESS_GROUPS_RAIL
    DIM_STORAGE_MASTER
    DIM_STORAGE_COST_RAIL
    DIM_STORAGE_CAPACITY_RAIL
    DIM_MATERIAL_RAIL
end

subgraph T2 [🌀 Subject Areas]
    direction TB
    SD_RAIL_AS_IS["Supply Demand Rail As Is"]
    LANES_MASTER_RAIL["Lanes Master Rail"]
    STORAGE_COST_RAIL["Storage Cost Rail"]
    STORAGE_CAPACITY_RAIL["Storage Capacity Rail"]
    LOCATION_RAIL["Location Rail"]
    MATERIAL_RAIL["Material Rail"]
    START_INV_RAIL["Starting Inventory Rail"]
end

subgraph T3 [📄 Reports]
    direction TB
    ShippedQty["Shipped Quantity Rail Parameter"]
    DemandRail["Demand Rail Parameter"]
    SupplyRail["Supply Rail Parameter"]
    TransportRail["Transportation Rail Parameter"]
    LocationReport["Location Rail Parameter"]
    MaterialReport["Material Rail Parameter"]
    StartInvReport["Starting Inventory Rail Parameter"]
    StorageCapacityReport["Storage Capacity Rail Parameter"]
    StorageCostReport["Storage Cost Rail Parameter"]
end

%% Straight connections: Tables → Subject Areas
FACT_ORDERS_AGGREGATED_EURO_AS --> SD_RAIL_AS_IS
DIM_LOCATION_RAIL --> SD_RAIL_AS_IS
DIM_STORAGE_SITES_PARENT_DAUGHTER_MAPPING --> SD_RAIL_AS_IS
FACT_ANTICIPATED_DEMAND_RAIL --> SD_RAIL_AS_IS
FACT_LANES_MASTER1 --> SD_RAIL_AS_IS

FACT_ORDERS_AGGREGATED_EURO_AS_IS --> LANES_MASTER_RAIL
DIM_LANE_ELIGIBILITY_RAIL --> LANES_MASTER_RAIL
DIM_STORAGE_SITE_ELIGIBILITY_EMPTY_RAIL --> LANES_MASTER_RAIL
FACT_TRIP_RAIL --> LANES_MASTER_RAIL
DIM_ROUTE_RAIL --> LANES_MASTER_RAIL
FACT_LOADED_TRANSPORT_COSTS_RAIL --> LANES_MASTER_RAIL
DIM_TVRO_RAIL --> LANES_MASTER_RAIL
DIM_ELIGIBLE_BUSINESS_GROUPS_RAIL --> LANES_MASTER_RAIL
DIM_STORAGE_MASTER --> LANES_MASTER_RAIL
DIM_STORAGE_SITES_PARENT_DAUGHTER_MAPPING --> LANES_MASTER_RAIL

DIM_STORAGE_COST_RAIL --> STORAGE_COST_RAIL
DIM_STORAGE_CAPACITY_RAIL --> STORAGE_CAPACITY_RAIL
DIM_LOCATION_RAIL --> LOCATION_RAIL
DIM_MATERIAL_RAIL --> MATERIAL_RAIL
DIM_LOCATION_RAIL --> START_INV_RAIL

%% Straight connections: Subject Areas → Reports
SD_RAIL_AS_IS --> ShippedQty
SD_RAIL_AS_IS --> DemandRail
SD_RAIL_AS_IS --> SupplyRail
LANES_MASTER_RAIL --> TransportRail
LOCATION_RAIL --> LocationReport
MATERIAL_RAIL --> MaterialReport
START_INV_RAIL --> StartInvReport
STORAGE_CAPACITY_RAIL --> StorageCapacityReport
STORAGE_COST_RAIL --> StorageCostReport