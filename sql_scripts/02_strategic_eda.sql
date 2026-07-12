SELECT *
FROM v_clean_retail_ecom_data;

-- distinguish a "high-revenue, narrow-margin anchor" from a "low-volume, high-markup niche"
SELECT
	product_category,
    SUM(quantity) total_quantity,
    ROUND(SUM(gross_sales), 2) total_sales,
    CONCAT(ROUND((SUM(order_profit) / NULLIF(SUM(gross_sales),0)) * 100, 2), '%' ) profit_margin
FROM v_clean_retail_ecom_data
GROUP BY product_category
ORDER BY total_sales DESC;



-- Apparel Return Rate: prove whether the issue is a regional warehouse delivery bottleneck 
-- or a product-specific manufacturing defect
SELECT
	customer_country,
	product_category,
	product_subcategory,
    CONCAT(ROUND((SUM(order_returned) / NULLIF(COUNT(DISTINCT order_id),0)) * 100, 2) , '%') return_rate
FROM v_clean_retail_ecom_data
WHERE product_category = 'Apparel'
GROUP BY customer_country, product_category, product_subcategory
ORDER BY product_category;

SELECT
    actual_shipping_days,
	product_category,
	product_subcategory,
    CONCAT(ROUND((SUM(order_returned) / NULLIF(COUNT(DISTINCT order_id),0)) * 100, 2) , '%') return_rate
FROM v_clean_retail_ecom_data
WHERE product_category = 'Apparel'
GROUP BY actual_shipping_days, product_category, product_subcategory
ORDER BY product_category;
 


-- evaluate the performance of our marketing campaigns
SELECT 
	marketing_campaign,
    CONCAT(ROUND((SUM(order_profit) / NULLIF(SUM(gross_sales),0)) * 100, 2), '%') profit_margin,
    ROUND(AVG(discount_amount), 2) avg_dicount_amount
FROM v_clean_retail_ecom_data
GROUP BY marketing_campaign
ORDER BY profit_margin DESC;


-- which marketing campaigns contribute the most to overall profit
WITH campaigns_profit AS (
	SELECT 
		marketing_campaign,
		ROUND(SUM(order_profit), 2) total_profit
	FROM v_clean_retail_ecom_data
	GROUP BY marketing_campaign
)
SELECT 
	marketing_campaign,
    total_profit,
    CONCAT(ROUND(total_profit / SUM(total_profit) OVER(), 2) * 100, '%' ) AS percent_of_total_profit
FROM campaigns_profit
ORDER BY total_profit DESC
;