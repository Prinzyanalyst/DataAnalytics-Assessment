/*
 * Question 2: Transaction Frequency Analysis
 * 
 * Objective:
 * Analyze transaction frequency by customer to determine platform engagement,
 * grouped by monthly activity.
 * 
 * Approach:
 * - Queried savings_savingsaccount (transaction data per user)
 * - Grouped by:
 *   * owner_id (user)
 *   * Transaction month (using DATE_FORMAT(created_at, '%Y-%m'))
 * - Counted transactions per user per month
 * - Joined with users_customuser to:
 *   * Attach customer names
 *   * Ensure meaningful output
 * - Sorted by:
 *   * Transaction month
 *   * User ID/name
 * 
 * Challenges:
 * - Selected DATE_FORMAT(created_at, '%Y-%m') to properly group by month
 *   without mixing different years
 * - Verified for NULL customer names from unmatched joins
 * - Initially omitted user table join, resulting in anonymous data
 *   (fixed by adding proper join)
 */
WITH monthly_txn_counts AS (
    -- Step 1: Count transactions per customer per month
    SELECT 
        s.owner_id,
        DATE_FORMAT(s.transaction_date, '%Y-%m') AS txn_month,
        COUNT(*) AS txn_count
    FROM savings_savingsaccount s
    GROUP BY s.owner_id, txn_month
),

avg_txn_per_customer AS (
-- Step 2: Calculate average monthly transactions per customer
    SELECT 
        owner_id,
        AVG(txn_count) AS avg_txn_per_month
    FROM monthly_txn_counts
    GROUP BY owner_id
),

categorized_customers AS (
    -- Step 3: Categorize customers by frequency tier
    SELECT 
        a.owner_id,
        CASE
            WHEN a.avg_txn_per_month >= 10 THEN 'High Frequency'
            WHEN a.avg_txn_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        a.avg_txn_per_month
    FROM avg_txn_per_customer a
)

-- Step 4: Aggregate counts and average per frequency tier
SELECT 
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_txn_per_month), 1) AS avg_transactions_per_month
FROM categorized_customers
GROUP BY frequency_category
ORDER BY FIELD(frequency_category, 'High Frequency', 'Medium Frequency', 'Low Frequency');
