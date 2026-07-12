-- Cleaning Data
SELECT *
FROM raw_retail_ecom_business_dataset
;

-- Fixing invalid quantity values 
SELECT 
	quantity,
    unit_price,
    gross_sales,
    gross_sales / unit_price AS quantity_clean
FROM raw_retail_ecom_business_dataset
WHERE quantity = -99;


-- Fixing invalid dates dates
SELECT 
	customer_acquisition_date,
	order_date, 
    shipping_date,
    delivery_date,
    actual_shipping_days,    
    CASE 
		WHEN order_date = '0000-00-00' OR order_date LIKE '%02-30%' 
			THEN DATE_SUB(shipping_date, INTERVAL 2 DAY)
		ELSE order_date
	END AS estimated_order_date,
    
	CASE 
		WHEN delivery_date = '0000-00-00' OR delivery_date LIKE '%02-30%' 
			THEN DATE_ADD(shipping_date, INTERVAL actual_shipping_days DAY)
		ELSE delivery_date
	END AS estimated_delivery_date,
    
    CAST(estimated_order_date AS DATE),
    CAST(estimated_delivery_date AS DATE),
    CAST(shipping_date AS DATE)
FROM raw_retail_ecom_business_dataset
WHERE 
	order_date = '0000-00-00'OR
    order_date LIKE '%02-30%' OR
    delivery_date = '0000-00-00' OR
    delivery_date LIKE '%02-30%';
    

SELECT 
    CEIL((AVG(TIMESTAMPDIFF(DAY, order_date, shipping_date)))) AS avg_gap,
    ROUND(MIN(TIMESTAMPDIFF(DAY, order_date, shipping_date)),2) AS min_gap,
    ROUND(MAX(TIMESTAMPDIFF(DAY, order_date, shipping_date)),2) AS max_gap
FROM raw_retail_ecom_business_dataset
WHERE 
	order_date <> '0000-00-00'AND
    order_date NOT LIKE '%02-30%' AND
    delivery_date <> '0000-00-00' AND
    delivery_date NOT LIKE '%02-30%';
    
    
-- Handling duplicates
WITH audited_duplicates_cte AS (
	SELECT *,
    ROW_NUMBER() OVER(
					PARTITION BY order_id, customer_id, order_profit_check
                ) AS exact_row_num
	FROM (
			SELECT *,
					ROUND(AVG(order_profit) OVER(PARTITION BY order_id), 2) AS order_profit_check
			FROM raw_retail_ecom_business_dataset
            ) AS subquery_table
),
clean_data AS (
	SELECT *
	FROM audited_duplicates_cte
	WHERE exact_row_num = 1
)
SELECT 
	order_id,
    customer_id,
    order_date,
    order_profit_check
	FROM clean_data
;

-- Standardizing Data
SELECT customer_country 
FROM raw_retail_ecom_business_dataset
;

SELECT DISTINCT product_category_clean
FROM (
SELECT *,
	CASE
		WHEN LOWER(TRIM(product_category)) IN ('electronics', ' electronics') THEN 'Electronics'
        WHEN LOWER(TRIM(product_category)) IN ('apparel', 'apparel & clothing') THEN 'Apparel'
        WHEN LOWER(TRIM(product_category)) IN ('home & kitchen', 'home/kitchen') THEN 'Home & Kitchen'
        WHEN LOWER(TRIM(product_category)) IN ('beauty & personal care') THEN 'Beauty & Personal Care'
        WHEN LOWER(TRIM(product_category)) IN ('sports & outdoors') THEN 'Sports & Outdoors'
        ELSE TRIM(product_category)
	END as product_category_clean,
    CASE
		WHEN LOWER(TRIM(customer_country)) = 'UK' THEN 'United Kingdom'
        WHEN LOWER(TRIM(customer_country)) = 'US' THEN 'United States'
        WHEN LOWER(TRIM(customer_country)) = 'DE' THEN 'Germany'
        ELSE TRIM(customer_country)
	END as customer_country_clean,
    CASE
		WHEN LOWER(TRIM(customer_state)) = 'أژle-de-France' THEN 'Île-de-France'
        ELSE TRIM(customer_state)
	END as customer_state_clean,
    CASE
		WHEN LOWER(TRIM(customer_city)) = 'lon' THEN 'London'
        WHEN LOWER(TRIM(customer_city)) = 'la' THEN 'Los Angeles'
        WHEN LOWER(TRIM(customer_city)) = 'ny' THEN 'New York'
        ELSE TRIM(customer_city)
	END as customer_city_clean,
    
    CONCAT(
		UPPER(LEFT(TRIM(product_subcategory), 1)),  
		LOWER(SUBSTRING(TRIM(product_subcategory), 2))
    )AS capitalized_product_subcategory,
    
    TRIM(shipping_mode) AS shipping_mode_clean,
    
    CONCAT(
		UPPER(LEFT(TRIM(customer_segment), 1)),  
		LOWER(SUBSTRING(TRIM(customer_segment), 2))
    )AS capitalized_customer_segment,
    
    TRIM(payment_method) AS payment_method_clean,
    
    CAST(NULLIF(customer_satisfaction_score, '') AS DECIMAL(2, 1)) AS customer_satisfaction_score_clean
    
FROM raw_retail_ecom_business_dataset
) AS summary_table;
    
    
    
-- Clean Data View
CREATE OR REPLACE VIEW v_clean_retail_ecom_data AS
WITH quality_assessment AS (
SELECT 
	order_id,
	customer_id,
	LOWER(TRIM(customer_segment)) AS customer_segment_clean,
	customer_acquisition_date,
	CASE
		WHEN LOWER(TRIM(customer_country)) = 'uk' THEN 'United Kingdom'
		WHEN LOWER(TRIM(customer_country)) = 'us' THEN 'United States'
		WHEN LOWER(TRIM(customer_country)) = 'de' THEN 'Germany'
		ELSE TRIM(customer_country)
	END as customer_country_clean,
	CASE
		WHEN LOWER(TRIM(customer_state)) LIKE '%le-de-france' THEN 'Île-de-France'
		ELSE TRIM(customer_state)
	END as customer_state_clean,
	CASE
		WHEN LOWER(TRIM(customer_city)) = 'lon' THEN 'London'
		WHEN LOWER(TRIM(customer_city)) = 'la' THEN 'Los Angeles'
		WHEN LOWER(TRIM(customer_city)) = 'ny' THEN 'New York'
        WHEN LOWER(TRIM(customer_city)) = 'torontoo' THEN 'Toronto'
		ELSE TRIM(customer_city)
	END as customer_city_clean,
	NULLIF(customer_zipcode, '') AS customer_zipcode_clean,
	region,
	sku,
	CASE
		WHEN LOWER(TRIM(product_category)) IN ('electronics', ' electronics') THEN 'Electronics'
		WHEN LOWER(TRIM(product_category)) IN ('apparel', 'apparel & clothing') THEN 'Apparel'
		WHEN LOWER(TRIM(product_category)) IN ('home & kitchen', 'home/kitchen') THEN 'Home & Kitchen'
		WHEN LOWER(TRIM(product_category)) IN ('beauty & personal care') THEN 'Beauty & Personal Care'
		WHEN LOWER(TRIM(product_category)) IN ('sports & outdoors') THEN 'Sports & Outdoors'
		ELSE TRIM(product_category)
	END as product_category_clean,
	CONCAT(
		UPPER(LEFT(TRIM(product_subcategory), 1)),  
		LOWER(SUBSTRING(TRIM(product_subcategory), 2))
	)AS product_subcategory_clean,
	product_name,
	CASE
		WHEN quantity = -99 THEN ROUND(gross_sales / NULLIF(unit_price, 0), 0)
		ELSE quantity
	END AS quantity_clean,
	unit_price,
	unit_cost,
	discount_percent,
	marketing_campaign,
	marketing_channel,
	marketing_cost_per_click,
    CONCAT(
		UPPER(LEFT(TRIM(shipping_mode), 1)),  
		LOWER(SUBSTRING(TRIM(shipping_mode), 2))
	)AS shipping_mode_clean,
	CASE 
		WHEN order_date = '0000-00-00' OR order_date LIKE '%02-30%' OR order_date = '' THEN NULL
		ELSE order_date
	END AS raw_order_date,
	CASE 
		WHEN shipping_date = '0000-00-00' OR shipping_date LIKE '%02-30%' OR shipping_date = '' THEN NULL
		ELSE shipping_date
	END AS raw_shipping_date,
	CASE 
		WHEN delivery_date = '0000-00-00' OR delivery_date LIKE '%02-30%' OR delivery_date = ''THEN NULL
		ELSE delivery_date
	END AS raw_delivery_date,
	actual_shipping_days,
	shipping_cost,
	shipping_charge_to_customer,
	LOWER(TRIM(payment_method)) AS payment_method_clean,
	CAST(NULLIF(customer_satisfaction_score, '') AS DECIMAL(2, 1)) AS customer_satisfaction_score_clean,
	order_returned
	
FROM raw_retail_ecom_business_dataset
),
recalculate_metrics_and_dates AS (
SELECT *,
	ROUND((unit_price * quantity_clean), 2) AS gross_sales_clean,
	ROUND((unit_cost * quantity_clean), 2) AS total_product_cost_clean,
	COALESCE(
		raw_order_date,
		DATE_SUB(raw_shipping_date, INTERVAL 2 DAY),
		DATE_SUB(raw_delivery_date, INTERVAL (actual_shipping_days + 2) DAY)
    ) AS estimated_order_date,
    COALESCE(
		raw_shipping_date,
		DATE_ADD(raw_order_date, INTERVAL 2 DAY),
		DATE_SUB(raw_delivery_date, INTERVAL actual_shipping_days DAY)
    ) AS estimated_shipping_date,
    COALESCE(
		raw_delivery_date,
		DATE_ADD(raw_shipping_date, INTERVAL actual_shipping_days DAY),
		DATE_ADD(raw_order_date, INTERVAL (actual_shipping_days + 2) DAY)
    ) AS estimated_delivery_date
    
FROM quality_assessment
),
financial_totals AS (
SELECT *,
		ROUND((gross_sales_clean * discount_percent), 2) AS discount_amount_clean,
        ROUND((gross_sales_clean - (gross_sales_clean * discount_percent)), 2) AS net_sales_clean,
        ROUND(((gross_sales_clean - (gross_sales_clean * discount_percent)) - total_product_cost_clean), 2) AS order_profit_clean
FROM recalculate_metrics_and_dates
),
audited_duplicates_cte AS (
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY order_id, customer_id, product_name, sku, order_profit_clean) AS exact_row_num
FROM financial_totals
)
SELECT 
	order_id,
	customer_id,
	customer_segment_clean AS customer_segment,
	customer_acquisition_date,
	customer_country_clean AS customer_country,
	customer_state_clean AS customer_state,
	customer_city_clean AS customer_city,
	customer_zipcode_clean AS customer_zipcode,
	region,
	sku,
	product_category_clean AS product_category,
	product_subcategory_clean AS product_subcategory,
	product_name,
	quantity_clean AS quantity,
	unit_price,
	unit_cost,
	gross_sales_clean as gross_sales,
	discount_percent,
	discount_amount_clean as discount_amount,
	net_sales_clean as net_sales,
	total_product_cost_clean as total_product_cost,
	order_profit_clean AS order_profit,
	marketing_campaign,
	marketing_channel,
	marketing_cost_per_click,
	CAST(estimated_order_date AS DATE) AS order_date,
	shipping_mode_clean AS shipping_mode,
	CAST(estimated_shipping_date AS DATE) AS shipping_date,
	CAST(estimated_delivery_date AS DATE) AS delivery_date,
	actual_shipping_days,
	shipping_cost,
	shipping_charge_to_customer,
	payment_method_clean AS payment_method,
	customer_satisfaction_score_clean AS customer_satisfaction_score,
	order_returned
FROM audited_duplicates_cte
WHERE exact_row_num = 1;