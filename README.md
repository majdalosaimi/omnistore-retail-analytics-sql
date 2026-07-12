# 📊 OmniStore Strategic Retail Analytics (SQL Execution)

## 📌 Project Overview
This project focuses on executing a rigorous end-to-end Extract-Transform-Load (ETL) pipeline, data sanitization protocol, and strategic business diagnostic review using **SQL**. The analytics framework is applied to a global multi-channel e-commerce operations dataset for **OmniStore Global Retail Group**. 

The raw dataset intentionally integrated complex database friction points, terminal script errors, and structural duplicates to simulate real-world data engineering constraints.

> **Note on Data Generation:** The underlying dataset used in this project was programmatically generated using AI tools to intentionally integrate complex database friction points, terminal script errors, and structural duplicates. This setup simulates a chaotic, real-world data engineering environment to test advanced SQL problem-solving capabilities.

---

## 🛠️ Data Quality Challenges & SQL Solutions

### 1. Advanced Deduplication Pass
* **Issue:** 120 injected duplicates split into 60 exact "double-click" matches and 60 partial "audit variances" with noise in profit logs.
* **SQL Solution:** Developed a single-pass Common Table Expression (CTE) utilizing `ROW_NUMBER() OVER(PARTITION BY ...)` to safely eliminate exact duplicates, while applying windowed `AVG()` partitioning to mathematically reconcile the terminal profit adjustments.

### 2. Temporal Imputation & Timeline Correction
* **Issue:** Corrupted calendar dates (e.g., `2024-02-30`) and system resets (`0000-00-00`) breaking timestamp pipelines.
* **SQL Solution:** Reconstructed missing delivery dates by adding `actual_shipping_days` to valid `shipping_date` logs. Order dates were imputed using conditional logic (`CASE WHEN`) leveraging the standard 2-day historical fulfillment gap (`DATE_SUB`).

### 3. Financial Recalculation Chain
* **Issue:** Injected 15x script multipliers in `gross_sales` caused cascading mathematical errors down to net profits.
* **SQL Solution:** Rebuilt the entire corporate revenue model from the ground up using core formulations (`Unit_Price * Quantity`) to ensure downstream logical alignment for `net_sales` and `order_profit`.

### 4. Categorical Inconsistency
* **Issue:** Legacy automated logs created typo variations (e.g., `'Electrnics'`, `'Home/Kitchen'`) and dynamic whitespace padding.
* **SQL Solution:** Standardized taxonomies using conditional logic optimized with `LOWER(TRIM(product_category))`.

---

## 📈 Core Strategic Insights

* **Apparel Return Crisis:** Pinpointed a severe margin drain in the Apparel portfolio where return rates spike above **20%**. SQL cross-examinations revealed a direct link where customer satisfaction scores of 1.0 hit a 100% return rate, driven by size mismatches and localized logistical delivery delays.
* **Promotional Margin Traps:** Audited marketing campaign performance by substituting top-line volumes with actual `total_profit` variables. Discovered that while `CAMP_BLACK_FRIDAY` drives massive transaction volumes, its heavy sitewide discounting erodes net margins to **~26%**, whereas targeted plays like `CAMP_RETARGET_90` maintain high-efficiency margins of **~51%**.

---

## 📂 Repository Structure
* `/sql_scripts`: Contains the modular production-ready SQL scripts for cleaning, recalculation, and exploratory metrics.
* `/data`: Reference documentation for schema parameters and data definitions.

## 🚀 How to Run the Scripts
1. Import the raw dataset into your SQL database engine.
2. Execute `01_data_cleaning.sql` to build the foundational clean layers.
3. Run the analytical queries within `02_strategic_eda.sql` to reproduce the strategic insights.
