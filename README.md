# DataAnalytics-Assessment
Solutions to the Data Analytics Assessment
This repository contains SQL queries written in MySQL to solve the given business questions. Each file corresponds to a specific question and includes clean formatting, inline comments, and a breakdown of the solution approach.

##  High-Value Customers with Multiple Products

**Objective:**  
Retrieve the top 1000 users based on combined deposits from regular savings and investment plans.

---

###  Approach

- Joined the `users_customuser` table with both `savings_savingsaccount` and `plans_plan`.
- Filtered for *funded* regular savings (`confirmed_amount > 0`) and *valid* investment plans (`is_a_fund = 1` and `amount > 0`).
- Summed:
  - `confirmed_amount` from savings, and  
  - `amount` from investment plans  
  (Note: Both in Kobo; converted to Naira by dividing by 100).
- Aggregated deposits per user and ordered the results by total deposit value in descending order.

---

###  Challenges

- Initially referenced a nonexistent column `confirmed_amount` in the `plans_plan` table.
- Fixed by switching to the correct column `amount` and applying an additional filter for investment plans.
- Also handled `NULL` values in user names by ensuring robust `JOIN` logic and careful field selection.

```sql
-- Identify users who have both funded savings and funded investment plans
SELECT 
    u.id AS owner_id,
    CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) AS name, -- Full name (combines first and last names; handles nulls)
    COUNT(DISTINCT s.id) AS savings_count,    -- Total number of funded savings accounts
    COUNT(DISTINCT i.id) AS investment_count,     -- Total number of funded investment plans
    ROUND(SUM(COALESCE(s.confirmed_amount, 0) + COALESCE(i.amount, 0)) / 100, 2) AS total_deposits -- Combined value of confirmed savings and investment amounts, converted from Kobo to Naira
FROM users_customuser u
JOIN savings_savingsaccount s -- Join to savings accounts with confirmed funding
    ON s.owner_id = u.id 
    AND s.confirmed_amount > 0
JOIN plans_plan i -- Join to investment plans that are marked as funds and have an amount
    ON i.owner_id = u.id 
    AND i.is_a_fund = 1 
    AND i.amount > 0
GROUP BY u.id, u.first_name, u.last_name
HAVING savings_count > 0 AND investment_count > 0 -- Filter users with both savings and investment records
ORDER BY total_deposits DESC -- Sort users by total deposits in descending order
LIMIT 1000;

---
