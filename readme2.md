### Files:
1. Main Model File: The primary Excel model where all data is consolidated.
2. Categorization Master File: The file containing categorization logic and updates.
3. Inventory File: The file with inventory data that needs regular updates.
4. GEM Data File: The file containing GEM data that requires refreshing to the latest date.
5. Pricing Data Files: Various sources for pricing data, including:
6. Planner estimates
   Actual Capex spend
   Inventory data
   Lassi pricing
   Open PO pricing
7. BUP Data File: The file with the latest BUP data.

1. **Categorization Master Update**
   - **Step 1**: Manual Mapping – This involves categorizing the master list of items manually to identify which belong to the AOP or OPS categories.
   - **Step 2**: GEM Update – The GEM data is refreshed using a script to pull the latest data.

2. **Pricing Logic**
   - **Sources of Pricing Data**:
     - Planner Estimates: Gathered from individual planner files, which track key categories.
     - Actual CAPEX Spend: Derived from the CAPEX budget file.
     - Inventory Data: Includes unit cost as a source of pricing.
     - Lassi Price: Data from a database provided by a specific planner.
     - Open View Pricing: Obtained from purchase order data.
   - **Step 1**: Prioritization – Pricing from different sources is prioritized using a pivot table. If a source does not provide pricing for a category, it is left blank.
   - **Step 2**: Variance Analysis – Identify significant quarterly differences in pricing for discussion and potential adjustments.

3. **Pivot Data Range and Formulas**
   - **Step 1**: Check Pivot Data Range – Ensure the pivot table captures the full data range.
   - **Step 2**: Extend Formulas – Ensure formulas cover all data within the pivot table.

### Step-by-Step Calculations and Views

1. **Categorization Master**
   - **Step 1**: Open the categorization master file.
   - **Step 2**: Manually map items to categories (AOP or OPS).
   - **Step 3**: Refresh GEM data:
     - Run the script to pull the latest GEM data.
     - Check if the data range in the pivot table covers all new data rows.
     - Ensure formulas in the pivot table extend to the last row.

2. **Pricing Logic**
   - **Step 1**: Collect pricing data from various sources:
     - **Planner Estimates**: Gather from individual planners.
     - **CAPEX Spend**: Extract from the CAPEX budget file.
     - **Inventory Data**: Use unit cost from the inventory database.
     - **Lassi Price**: Get from the Lassi database via the responsible planner.
     - **Open View Pricing**: Calculate from purchase order data.
   - **Step 2**: Create a pivot table to list pricing from each source for each category.
   - **Step 3**: Prioritize pricing using the pivot table:
     - For each category, check if pricing data is available from each source.
     - Apply a simple prioritization logic to select the most appropriate pricing.

3. **Pivot Data Range and Formulas**
   - **Step 1**: Verify the pivot table's data range:
     - Check the last row number of the new data.
     - Update the pivot table's data range to include all new rows.
   - **Step 2**: Extend formulas:
     - Ensure all formulas in the pivot table extend to the new last row.
     - Verify that all data points are covered by the updated formulas.

4. **Date Check and Refresh**
   - **Step 1**: Check for the latest available data dates in inventory files.
   - **Step 2**: Run the date check script to confirm the availability of data for the desired date.
   - **Step 3**: Refresh data based on the latest available date.

BUP Data Handling:
Refresh the latest BUP data.
Ensure proper categorization and linkage with other data sets.
Verify and update formulas involving BUP data.
Step-by-Step Guide for Including BUP Data
Step 1: Refresh BUP Data

Identify Latest BUP Data:

Check the source file or database for the most recent BUP data.
Note the date of the latest available data.
Update BUP Data in the Model:

Import the latest BUP data into the main model.
Ensure all relevant fields are updated to reflect the new data.
Step 2: Categorize and Link BUP Data

Categorization:

Use the categorization master to classify the BUP data.
Update any new categories or changes in existing categories.
Link BUP Data to Other Data Sets:

Ensure BUP data is correctly linked with inventory, pricing, and other relevant data sets.
Verify the integrity of links and references to avoid broken connections.
Step 3: Verify and Update Formulas

Check Formulas Involving BUP Data:

Identify all formulas in the model that use BUP data.
Ensure these formulas are updated to reflect the latest data.
Adjust Pivot Tables:

Extend pivot table ranges to include the new BUP data.
Ensure pivot tables accurately reflect the updated data.
Step 4: Finalize Updates

Refresh Main Model:

Refresh the main model to pull in the updated BUP data.
Verify that all updates are correctly reflected in the model.
Validation:

Cross-check BUP data with other data sets for consistency.
Ensure all categories and links are correctly applied.