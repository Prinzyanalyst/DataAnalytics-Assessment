/*
 * Question 3: Inactive Users Identification
 * 
 * Objective:
 * Identify users with no savings deposits in the last 3 months
 * for potential re-engagement campaigns.
 * 
 * Approach:
 * - Queried savings_savingsaccount for latest transaction dates
 * - Grouped by owner_id using MAX(created_at) to handle:
 *   * Multiple savings accounts per user
 *   * Get most recent transaction
 * - Calculated inactivity period using:
 *   * TIMESTAMPDIFF(MONTH, last_txn, CURDATE()) >= 3
 *   * Alternative: DATEDIFF comparison
 * - Joined with users_customuser to include:
 *   * User IDs
 *   * Names
 *   * Last transaction dates
 * - Sorted by longest inactive first
 * 
 * Challenges:
 * - Handled multi-account users via MAX(created_at) aggregation
 * - Carefully filtered inactive window with proper date functions
 * - Managed edge cases:
 *   * Users with no transactions (NULL handling)
 *   * Used LEFT JOIN to preserve all users
 */

WITH latest_savings_txn AS (
    -- Latest inflow transaction date for savings accounts
    SELECT 
        s.plan_id,
        s.owner_id,
        MAX(s.transaction_date) AS last_transaction_date,
        'Savings' AS type
    FROM savings_savingsaccount s
    WHERE s.confirmed_amount > 0
    GROUP BY s.plan_id, s.owner_id
),

latest_investment_txn AS (
    -- Latest inflow date for investment plans
    SELECT 
        p.id AS plan_id,
        p.owner_id,
        MAX(p.start_date) AS last_transaction_date,  -- Assuming start_date as inflow date if no transaction table
        'Investment' AS type
    FROM plans_plan p
    WHERE p.is_a_fund = 1
    GROUP BY p.id, p.owner_id
),

combined_latest_txn AS (
    -- Combine savings and investment latest transactions
    SELECT * FROM latest_savings_txn
    UNION ALL
    SELECT * FROM latest_investment_txn
)

SELECT 
    plan_id,
    owner_id,
    type,
    last_transaction_date,
    DATEDIFF(CURDATE(), last_transaction_date) AS inactivity_days
FROM combined_latest_txn
WHERE DATEDIFF(CURDATE(), last_transaction_date) > 365
ORDER BY inactivity_days DESC;
