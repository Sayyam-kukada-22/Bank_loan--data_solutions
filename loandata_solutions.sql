Q1: Loan Approval Rate Overview  
    Management wants to know: What % of applications were approved vs rejected?

SELECT 
    COUNT(*) AS applicants,
    loan_status,
    (COUNT(loan_status) * 100.0 / (SELECT COUNT(*) FROM loans)) AS applicants_status
FROM loans 
GROUP BY 

Q2: Graduate vs Non-Graduate Applicants
   Education dept: Count applicants by education category
   

SELECT 
    COUNT(*) AS applicants,
    education
FROM loans 
GROUP BY education;


Q3: High-Value Loan Applicants
    Risk team: Loan amount > ₹1 Crore


SELECT * 
FROM loans
WHERE loan_amount > 10000000;


Q4: Self-Employed Applicants Report
    Finance team: Count & avg income of self-employed


SELECT 
    COUNT(*) AS applicants,
    self_employed,
    ROUND(AVG(income_pa), 2) AS avg_income
FROM loans 
WHERE self_employed ILIKE '%yes'
GROUP BY self_employed;


Q5: Applicants with No Dependents
    Credit policy: Approved loans with 0 dependents

SELECT *
FROM loans
WHERE no_of_dependents = 0 
  AND loan_status ILIKE '%approved';



Q6: Loan Term Distribution
-- Product team: Popular loan terms
-- ============================================================

SELECT 
    COUNT(loan_id) AS applicants,
    loan_term
FROM loans
GROUP BY loan_term
ORDER BY applicants DESC;


Q7: Top 10 Highest Income Applicants
     Premium banking: Top earners & loan status


SELECT 
    income_pa,
    loan_status
FROM loans 
ORDER BY income_pa DESC 
LIMIT 10;



Q8:  CIBIL Score Risk Segmentation
     Risk dept: Categorize applicants & approvals/rejections


SELECT 
    COUNT(*) AS applicants,
    loan_status,
    CASE 
        WHEN cibil_score > 750 THEN 'Excellent' 
        WHEN cibil_score BETWEEN 650 AND 749 THEN 'Good'
        WHEN cibil_score BETWEEN 550 AND 649 THEN 'Fair'
        ELSE 'Poor' 
    END AS category
FROM loans
GROUP BY loan_status, category
ORDER BY applicants DESC;



Q9: Income vs Loan Amount Ratio Analysis
    Underwriting: Flag risky applicants (loan > 10x income)
	

SELECT * 
FROM loans
WHERE loan_amount > income_pa * 10;

SELECT * 
FROM loans
WHERE loan_amount > income_pa * 10;



Q10: Approval Rate by Education & Employment Type
     Analytics: Compare approval rates for 4 groups


SELECT 
    TRIM(education) AS education,
    CASE 
        WHEN self_employed ILIKE '%yes' THEN 'Self-Employed'
        ELSE 'Salaried'
    END AS employment_type,
    CASE 
        WHEN education ILIKE '%graduate' AND self_employed ILIKE '%no'  
            THEN 'Graduate+Salaried'
        WHEN education ILIKE '%graduate' AND self_employed ILIKE '%yes' 
            THEN 'Graduate+Self-Employed'
        WHEN education ILIKE '%not graduate' AND self_employed ILIKE '%no'  
            THEN 'Non-Graduate+Salaried'
        ELSE 'Non-Graduate+Self-Employed'
    END AS category,
    COUNT(*) AS total_applicants,
    SUM(CASE WHEN loan_status ILIKE '%approved' THEN 1 ELSE 0 END) AS approved,
    ROUND(SUM(CASE WHEN loan_status ILIKE '%approved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS approval_rate
FROM loans
GROUP BY education, self_employed 
ORDER BY approval_rate DESC;


Q11: Total Asset Worth per Applicant
     Collateral team: Top 20 wealthiest applicants

SELECT 
    loan_id,
    education,
    loan_term,
    loan_status,
    (residental_assets_value + commercial_asset_value + luxury_assets_value + bank_asset_value) AS total_assets
FROM loans
ORDER BY total_assets DESC 
LIMIT 20;



Q12: Dependents Impact on Loan Approval
     Policy research: Approval % by dependent count


SELECT 
    COUNT(*) AS applicants,
    no_of_dependents, 
    ROUND(SUM(CASE WHEN loan_status ILIKE '%approved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS approval_percentage
FROM loans 
GROUP BY no_of_dependents
ORDER BY no_of_dependents;



Q13: Rejected Applicants with Good CIBIL Score
     Grievance cell: Rejected cases with CIBIL > 700

 
SELECT * 
FROM loans
WHERE cibil_score > 700 
  AND loan_status ILIKE '%rejected';



Q14: Average Loan Amount by Loan Term
     Product pricing: Avg loan size per term


SELECT 
    ROUND(AVG(loan_amount), 2) AS avg_loan,
    loan_term
FROM loans
GROUP BY loan_term
ORDER BY avg_loan DESC;


Q15: Bank Asset vs Loan Amount Gap
     Credit risk: Applicants with insufficient liquid assets



SELECT * 
FROM loans
WHERE bank_asset_value < loan_amount;


Q16: Percentile Ranking of Applicants by Income
     Dashboard: Top 5% earners & loan status


WITH top_income_earners AS (
    SELECT 
        loan_id,
        loan_status,
        income_pa,
        education,
        percent_rank() OVER (ORDER BY income_pa) * 100 AS top_percents
    FROM loans
)
SELECT * 
FROM top_income_earners
WHERE top_percents > 95
ORDER BY top_percents DESC;


Q17: Running Total of Loan Amount Disbursed
     Finance team: Cumulative disbursement tracker


SELECT 
    loan_id,
    loan_amount,
    SUM(loan_amount) OVER (ORDER BY loan_id) AS cumulative_loans
FROM loans;



Q18: Identify Anomalies — High Assets, Rejected Loans
      Audit team: Assets > avg, CIBIL > 650, rejected


WITH TA AS (
    SELECT 
        loan_id,
        education,
        loan_status,
        loan_amount,
        income_pa,
        cibil_score,
        (residental_assets_value + commercial_asset_value + luxury_assets_value + bank_asset_value) AS total_assets
    FROM loans
),
avg_asset AS (
    SELECT ROUND(AVG(total_assets), 2) AS avg_assets 
    FROM TA
)
SELECT 
    t.loan_id,
    t.education,
    t.loan_status,
    t.loan_amount,
    t.income_pa,
    t.total_assets,
    t.cibil_score,
    av.avg_assets
FROM TA t 
CROSS JOIN avg_asset av 
WHERE t.total_assets > av.avg_assets  
  AND t.cibil_score > 650 
  AND t.loan_status ILIKE '%rejected';



Q19: CIBIL Score Bucket — Approval Rate Trend
     Data science: Buckets of 50 points, approval % & rank


WITH cibil_buckets AS (
    SELECT 
        (cibil_score / 50) * 50 AS bucket_start,
        SUM(CASE WHEN loan_status ILIKE '%approved' THEN 1 ELSE 0 END) AS approved_applicants,
        COUNT(*) AS total_applicants,
        ROUND(SUM(CASE WHEN loan_status ILIKE '%approved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS approval_rates
    FROM loans 
    GROUP BY (cibil_score / 50) * 50
)
SELECT 
    bucket_start,
    bucket_start || '-' || (bucket_start + 50) AS cibil_buckets,
    total_applicants,
    approved_applicants,
    approval_rates,
    RANK() OVER (ORDER BY approval_rates DESC) AS approval_ranks
FROM cibil_buckets
ORDER BY approval_ranks;



Q20: Loan Approval Prediction Score Card
     Weighted scoring: CIBIL(40%) + Income(30%) + Assets(20%) + Low Dependents(10%)


WITH total_assets AS (
    SELECT 
        (residental_assets_value + commercial_asset_value + luxury_assets_value + bank_asset_value) AS TA,
        loan_id,
        loan_status,
        cibil_score,
        no_of_dependents,
        income_pa,
        education
    FROM loans
),
fair_num AS (
    SELECT 
        (cibil_score - MIN(cibil_score) OVER()) * 1.0 / (MAX(cibil_score) OVER() - MIN(cibil_score) OVER()) AS cibil_fair,
        (TA - MIN(TA) OVER()) * 1.0 / (MAX(TA) OVER() - MIN(TA) OVER()) AS assets_norm,
        (income_pa - MIN(income_pa) OVER()) * 1.0 / (MAX(income_pa) OVER() - MIN(income_pa) OVER()) AS income_norm,
        (no_of_dependents - MIN(no_of_dependents) OVER()) * 1.0 / (MAX(no_of_dependents) OVER() - MIN(no_of_dependents) OVER()) AS dependents_norm,
        loan_id,
        loan_status,
        cibil_score,
        no_of_dependents,
        income_pa,
        TA,
        education
    FROM total_assets
),
weightage_scores AS (
    SELECT 
        loan_id,
        loan_status,
        education,
        no_of_dependents,
        cibil_score,
        TA,
        ROUND(
            (cibil_fair * 40) +
            (assets_norm * 20) +
            (income_norm * 30) +
            ((1 - dependents_norm) * 10), 2
        ) AS final_score
    FROM fair_num
)
SELECT 
    loan_id,
    education,
    loan_status,
    no_of_dependents,
    cibil_score,
    TA,
    final_score,
    RANK() OVER (ORDER BY final_score DESC) AS final_ranks
FROM weightage_scores
ORDER BY final_ranks
LIMIT 20;	 





  








