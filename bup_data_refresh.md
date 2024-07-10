# Calculating BUP Report

## Precautionary Step:
Ensure the file contains no more than 25,000 rows.

## Input Files:
1. **Main Model File**: The primary Excel model where all data is consolidated.
2. **Categorization Master File**: Contains categorization logic and updates.
3. **Pricing Logic Data Files**: Various sources for pricing data, including:
   - Planner estimates
   - Actual Capex spend
   - Inventory data
   - Lassi pricing
   - Open PO pricing
4. **BUP Demand RR**: Contains the latest BUP data.
5. **Capex Budget**: Not required.
6. **Ops Plan**: Not required.
7. **Inventory File**: Contains inventory data requiring regular updates.
8. **Entitlement**
9. **Open PO**
10. **Actual Capex Spent**
11. **Supply Commits**: Not in use.
12. **ML% Segmentation Dashboard**

## Step-by-Step Calculations and Views

### 1. Categorization Master Update
- **Step 1: Manual Mapping**
  - Categorize the master list of items manually to identify which belong to the CAPEX (AOP) File or OPS categories.
- **Step 2: GCM Update**
  - View: For each planning category, include `gem_type` and `total_cost`.
  - GCM Item Type (A to K - similar to ABC categories)
  - Update the GCM data using a script:
    - Dependent tables: `bees.DailyInventorySnapshots` and `bees.ItemMaster`
    - Pull date: Use the latest data, as BUP is a "To Go" file and doesn't require historical data.
  - Check the Inventory file (Datecheck sheet) for the data date.
- **Step 3: Update GCM Type (Sheet)**
  - Pivot the GCM data on the GCM type.
  - Check pivot formulas and the data range in the pivot table.
  - Ensure formulas cover all new data rows.
  - Pass GCM data to the Main model in the Flags GCM columns.

### 2. Pricing Logic
- Update once a quarter or as discussed.
- **Sources of Pricing Data**:
  - Planner Estimates: From individual planner files.
  - Actual CAPEX Spend: From the CAPEX budget file.
  - Inventory Data: Includes unit cost.
  - Lassi Price: From a database provided by a specific planner.
  - Open PO Pricing: From purchase order data.
- **Step 1: Prioritization**
  - Use a pivot table to prioritize pricing from different sources. Leave blank if a source doesn't provide pricing.
- **Step 2: Variance Analysis**
  - Extend formulas in the pivot table.
  - Remove rows where price is zero or blank.

### 3. BUP Demand RR (Take Backup)
- Check links in the control tab:
  - Dependent on categorization logic, pricing logic, and inventory.
  - Capex Reduction Plan Model.
- **RR Data Pull**
  - Dependent tables:
    - `bees.ItemMaster`
    - `bees.Odw_sp_RRPlannedorders`
    - `bees.odw_base_ScheduledReceipt_History`
    - Copy of Plant Group Mapping (Excel file)
  - Pull data for the planning category against `required` and `sum_spares` from today on a quarterly basis.
  - Refresh the data in the Raw Data sheet.
  - Update dates in the Reade sheet and Control tab.
  - Validate the data for errors and ensure it covers forward quarters.

### 4. Inventory
- Update the snapshot date in the ReadMe sheet.
- Validate data in the Raw Data sheet.
- Check Pivot Table 1 sheet for consistency with previous pulls.
- Check for new categories in the category check sheet.

### 5. Entitlement
- Update the last refresh date in the ReadMe.
- Take a backup of the last data pull sheet (Data Sheet 1).
- **Data Sheet 1**:
  - Dependent table: `bees.InventoryEntitlement`
  - Pull data for each planning category against respective `OH`, `spares inventory`, `entitlement`, and `weekly_demand_aty`.
- Validate entitlement data in the Raw Data sheet.

### 6. Open PO
- Update the snapshot date.
- Save previous pull data and fetch new data using PO data_2 sheet.
- Dependent tables:
  - `bees.POMaterialopenLiabilities`
  - `bees.ItemMaster`
  - Pull data for `shipment_need_by_quarter_up`, `PO_Ordered`, `PO_Delivered`, `PO_Open` against each planning category.
- Validate PO data in the Raw Data sheet.

### 7. Actual Capex Spent
- Update the last refresh date.
- Similar to the Capex Budget sheet, pull data for specific dates.
- Dependent tables:
  - `bees.ItemMaster`
  - `bees.MachineCapex`
  - Data pull columns: `net_quantity`, `net_value_usd`, `planning_category`.
- Validate data in the Raw Data and Pivot sheets.

### 8. ML% Segmentation Dashboard
- Archive the last pull data.
- **Data Sheet 1**:
  - Dependent table: `bees.nectar.ml_non_ml.inventory_cy_ml_ratios.latest`
  - Data includes `primary_planning_category`, `planning_category`, `ml_ratio`, `ml_ratio_amplification`.
  - Validate planning categories are unique.

### Note:
ML update will also impact the projection file: Summary View FY.


  # BUP Report Calculation Process Flow Diagram

```plaintext
                          ┌───────────────┐
                          │ Main Model    │
                          │ File          │
                          └──────┬────────┘
                                 │
                                 │
                                 ▼
┌───────────────┬───────────────┼────────────────────┬───────────────┬───────────────────┬───────────────┐──────────────────────────────────────────┐
│               │               │                    │               │                   │               │                                          │  
▼               ▼               ▼                    ▼               ▼                   ▼               ▼                                          ▼
▼               ▼               ▼                    ▼               ▼                   ▼               ▼                                          ▼
┌───────────────┐ ┌─────────────┐ ┌─────────────────┐ ┌──────────────┐ ┌────────────────────┐  ┌──────────────┐ ┌───────────────┐
│ Categorization│ │ Pricing      │ │ BUP Demand RR   │ │ Inventory    │ │ Entitlement        │ │ Open PO      │ │ Actual Capex  │           ┌─────────────────┐
│ Master File   │ │ Logic Data   │ │                 │ │ File         │ │                    │ │              │ │ Spent Update  │           │ ML% Segmentation│
│               │ │ Files        │ │                 │ │              │ │                    │ │              │ │               │           │ Dashboard       │
└──────┬────────┘ └──────┬───────┘ └──────────┬──────┘ └──────┬───────┘ └─────────┬──────────┘ └───────┬──────┘ └───────────────┘           └─────────────────┘
       │                │                    │               │                    │                    │                    │
       │                │                    │               │                    │                    │                    │
       ▼                ▼                    ▼               ▼                    ▼                    ▼                    ▼
┌──────┴────────┐ ┌─────┴────────┐ ┌─────────┴─────────┐ ┌───┴──────────┐ ┌──────┴──────────┐ ┌───────┴──────┐ ┌───────────────┐
│ Step 1: Manual │ │ Step 1:      │ │ RR Data Pull     │ │ Snapshot Date│ │ Last Refresh    │ │ Validate Open│ │ Validate Data  │
│ Mapping        │ │ Prioritization│ │                 │ │ in ReadMe    │ │ Date in ReadMe  │ │ PO Data in   │ │ in Raw Data    │
└──────┬─────────┘ └─────┬────────┘ └───────┬──────────┘ └────┬──────────┘ └───────┬─────────┘ │ Raw Data Sheet│ │ Sheet          │
       │                 │                  │                 │                    │           └───────┬──────┘ └───────────────┘
       ▼                 ▼                  ▼                 ▼                    ▼                   │
┌──────┴─────────┐ ┌─────┴────────┐ ┌───────┴───────────┐ ┌───┴──────────┐ ┌──────┴──────────┐ ┌───────┴──────┐
│ Step 2: GCM    │ │ Step 2:      │ │ Update dates in  │ │ Validate Raw │ │ Data Sheet 1    │ │ Validate Data │
│ Update         │ │ Variance     │ │ Reade sheet      │ │ Data Sheet   │ │ Backup          │ │ for New       │
└──────┬─────────┘ │ Analysis     │ └───────┬──────────┘ └────┬──────────┘ └───────┬─────────┘ │ Categories    │
       │           └─────┬────────┘         │                 │                    │           │ in Categoriza-│
       ▼                 │                  ▼                 ▼                    ▼           │ tion Sheet    │
┌──────┴─────────┐ ┌─────┴────────┐ ┌───────┴───────────┐ ┌───┴──────────┐ ┌──────┴──────────┐ └─────────────┘
│ Step 3: Update │ │ Step 3:      │ │ Validate data for│ │ Check Pivot  │ │ Validate Data   │         
│ GCM Type       │ │ Remove rows  │ │ errors and ensure│ │ Table 1 Sheet│ │ in Raw Data     │         
│                │ │ where price  │ │ it covers forward│ │              │ │ Sheet           │ 
│                │ │ is zero or   │ │ quarters         │ └────┬──────────┘ └───────┬─────────┘ 
│                │ │ blank        │ └───────┬──────────┘      │                    │           
└──────┬─────────┘ └─────┬────────┘         │                 │                    │           
       │                 │                  ▼                 ▼                    ▼
       ▼                 │           ┌──────┴───────────┐ ┌───┴──────────┐ ┌──────┴──────────┐
┌──────┴─────────┐       │           │ Validate Data    │ │ Check for New│ │ Pull Data for  │
│ GCM Type Passed│       │           │ in Inventory     │ │ Categories   │ │ Open PO        │
│ to Main Model  │       │           │ File             │ │              │ │                │
└────────────────┘       │           └──────┬───────────┘ └────┬──────────┘ └───────┬─────────┘
                         │                  │                 │                    │
                         │                  ▼                 ▼                    ▼
                         │           ┌──────┴───────────┐ ┌───┴──────────┐ ┌──────┴──────────┐
                         │           │ Data Sheet 1     │ │ Validate Open│ │ Validate Data   │
                         │           │ Update           │ │ PO Data in   │ │ for New         │
                         │           └──────┬───────────┘ │ Raw Data Sheet│ │ Categories      │
                         │                  │             └────┬──────────┘ │ in Categoriza-  │
                         │                  ▼                  │             │ tion Sheet      │
                         │           ┌──────┴───────────┐      ▼             └───────┬─────────┘
                         │           │ Update Last      │ ┌────┴──────────┐          │
                         │           │ Refresh Date     │ │ Validate Data │          ▼
                         │           └──────┬───────────┘ │ in Raw Data   │ ┌───────────────┐
                         │                  │             │ Sheet         │ │ Validate Data │
                         │                  ▼             └────┬──────────┘ │ (planning     │
                         │           ┌──────┴───────────┐      │            │ category      │
                         │           │ Validate Data    │      ▼            │ should be     │
                         │           │ in Pivot Sheets  │ ┌────┴──────────┐ │ unique)       │
                         │           └──────┬───────────┘ │ Archive Last  │ └───────────────┘
                         │                  │             │ Pull Data     │
                         │                  ▼             └────┬──────────┘
                         ▼           ┌──────┴───────────┐      │
                ┌───────┴──────────┐ │ Archive Last     │      ▼
                │ ML Update        │ │ Pull Data        │ ┌───────────────┐
                │ Impacts the      │ └──────┬───────────┘ │ Data Pull     │
                │ Projection File  │        │             │ Script        │
                └──────────────────┘        ▼             └───────────────┘
                                       ┌────┴───────────┐
                                       │ Data Pull Script │
                                       └──────────────────┘
