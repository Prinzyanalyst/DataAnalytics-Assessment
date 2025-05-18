/*
 * Question 4: Customer Lifetime Value (CLV) Estimation
 * 
 * Objective:
 * Estimate CLV based on savings behavior and user tenure since registration.
 * 
 * Approach:
 * - Created CTE (customer_transactions) to calculate:
 *   * Total savings transactions per user
 *   * Total confirmed_amount value
 * - Created CTE (customer_tenure) to calculate:
 *   * Tenure in months (TIMESTAMPDIFF(MONTH, date_joined, CURDATE()))
 * - Merged datasets via JOIN on owner_id/id
 * - CLV Formula:
 *   (transactions/month) * 12 * 0.1% * avg_transaction_value
 *   Implementation:
 *   (total_transactions/tenure_months)*12*0.001*(total_value/100)
 * - Applied:
 *   * ROUND() for currency precision
 *   * NULLIF() to prevent division by zero
 * 
 * Challenges:
 * - Fixed column mismatch from customer_id alias
 * - Resolved NULL names via secondary users_customuser join
 * - Ensured Kobo→Naira conversion (/100)
 * - Safely handled zero-tenure cases with NULLIF */

-- CTE 1: Calculate transaction activity per customer
WITH customer_transactions AS (
    SELECT 
        s.owner_id,
        COUNT(*) AS total_transactions,             -- Total number of savings transactions
        SUM(s.confirmed_amount) AS total_value      -- Total transaction value (in Kobo)
    FROM savings_savingsaccount s
    GROUP BY s.owner_id
),

-- CTE 2: Calculate each customer's tenure since sign-up
customer_tenure AS (
    SELECT 
        u.id AS customer_id,

        -- Ensure name is not null: I fallback to first and last name
        COALESCE(u.name, CONCAT_WS(' ', u.first_name, u.last_name)) AS name,

        -- Tenure in months between account creation and today
        TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months
    FROM users_customuser u
)

-- Final selection and CLV estimation
SELECT 
    ct.customer_id,
    ct.name,
    ct.tenure_months,
    COALESCE(t.total_transactions, 0) AS total_transactions,  -- Default to 0 if no transactions recorded
    -- CLV formula:
    -- CLV = (Monthly transactions) * 12 * 0.1% * average transaction value (in Naira)
    ROUND(
        (COALESCE(t.total_transactions, 0) / NULLIF(ct.tenure_months, 0)) * 12 * 0.001 * 
        COALESCE(t.total_value, 0) / 100,          -- Divide by 100 to convert Kobo to Naira
        2                                          -- Round to 2 decimal places
    ) AS estimated_clv
FROM customer_tenure ct
LEFT JOIN customer_transactions t 
    ON ct.customer_id = t.owner_id
ORDER BY estimated_clv DESC; -- Sort by highest estimated CLV
