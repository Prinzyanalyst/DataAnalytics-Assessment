/*
 * High-Value Customers with Multiple Products
 * 
 * Objective:
 * Retrieve the top 1000 users based on combined deposits from regular savings 
 * and investment plans.
 * 
 * Approach:
 * - Joined users_customuser table with both savings_savingsaccount and plans_plan
 * - Filtered for:
 *   * Funded regular savings (confirmed_amount > 0)
 *   * Valid investment plans (is_a_fund = 1 and amount > 0)
 * - Summed:
 *   * confirmed_amount from savings
 *   * amount from investment plans
 *   (Note: Both in Kobo; converted to Naira by dividing by 100)
 * - Aggregated deposits per user
 * - Ordered by total deposit value in descending order
 * 
 * Challenges:
 * - Initially referenced non-existent column confirmed_amount in plans_plan table
 * - Fixed by:
 *   * Using correct column 'amount'
 *   * Adding filter for investment plans
 * - Handled NULL values in user names through robust JOIN logic
 * - Ensured careful field selection
 */

SELECT 
    u.id AS owner_id,
    CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) AS name,     -- Full name (combines first and last names; handles nulls)
    COUNT(DISTINCT s.id) AS savings_count,    -- Total number of funded savings accounts
    COUNT(DISTINCT i.id) AS investment_count,     -- Total number of funded investment plans
    ROUND(SUM(COALESCE(s.confirmed_amount, 0) + COALESCE(i.amount, 0)) / 100, 2) AS total_deposits   -- Combined value of confirmed savings and investment amounts, converted from Kobo to Naira
FROM users_customuser u
JOIN savings_savingsaccount s -- Join to savings accounts with confirmed funding
    ON s.owner_id = u.id 
    AND s.confirmed_amount > 0
JOIN plans_plan i -- Join to investment plans that are marked as funds and have an amount
    ON i.owner_id = u.id 
    AND i.is_a_fund = 1 
    AND i.amount > 0
GROUP BY u.id, u.first_name, u.last_name
HAVING savings_count > 0 AND investment_count > 0 -- -- Filter users with both savings and investment records
ORDER BY total_deposits DESC; -- Sort users by total deposits in descending order