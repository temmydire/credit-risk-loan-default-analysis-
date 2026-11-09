CREATE DATABASE `Credit_Risk_Project`;
USE `Credit_Risk_Project`;

CREATE TABLE borrowers (
borrower_id VARCHAR(20),
annual_income INT,
credit_score_raw INT,
employment_length_years INT,
home_ownership VARCHAR(50),
PRIMARY KEY (borrower_id)
);

CREATE TABLE loans (
loan_id VARCHAR(20),
borrower_id VARCHAR(20),
loan_amount DECIMAL(10,2),
origination_date DATE,
loan_intent VARCHAR(50),
loan_grade VARCHAR(10),
account_status VARCHAR(50),
PRIMARY KEY (loan_id),
FOREIGN KEY (borrower_id)
REFERENCES borrowers(borrower_id)
);

CREATE TABLE loan_ledger (
snapshot_date DATE,
loan_id VARCHAR(20),
monthly_payment_due DECIMAL(10,2),
amount_paid DECIMAL(10,2),
days_past_due INT
);

LOAD DATA LOCAL INFILE "C:/Program Files/MySQL/MySQL Server 8.0/Uploads/borrowers.csv"
INTO TABLE borrowers
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

SHOW WARNINGS;

LOAD DATA LOCAL INFILE "C:/Program Files/MySQL/MySQL Server 8.0/Uploads/loans.csv"
INTO TABLE loans 
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SHOW WARNINGS;

LOAD DATA LOCAL INFILE "C:/Program Files/MySQL/MySQL Server 8.0/Uploads/loan_ledger.csv"
INTO TABLE loan_ledger 
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SHOW WARNINGS;
-- (load): all three files loaded with no warnings. Row counts reconciled:
-- borrowers (1000), loans (10540), loan_ledger (145755) (matches the source files).

EXPLAIN SELECT * 
FROM loan_ledger
WHERE loan_id = 'LN-10234'
ORDER BY snapshot_date;

CREATE INDEX idx_ledger_loan_date 
ON loan_ledger (loan_id, snapshot_date);

EXPLAIN SELECT *
FROM loan_ledger
WHERE loan_id = 'LN-10234'
ORDER BY snapshot_date;

SHOW INDEX 
FROM loan_ledger;
-- I created an index on (loan_id, snapshot_date) because my main queries start from loan_id.

SELECT *
FROM borrowers;
-- --10,000 rows and 10,000 distinct borrower_ids.

SELECT COUNT(*) AS total_rows, COUNT(DISTINCT borrower_id)
FROM borrowers;

SELECT  min(annual_income) AS MINIMUM,max(annual_income) AS MAXIMUM,avg(annual_income) AS AVERAGE
FROM borrowers;
-- income ranges from 18,000 to 250,000 (avg 61,009.07);.

SELECT  min(employment_length_years) as MINIMUM,max(employment_length_years) AS MAXIMUM,avg(employment_length_years) AS AVERAGE
FROM borrowers;
 -- tenure 0 to 20 (avg 6.52)-- 
 
SELECT credit_score_raw, COUNT(*) as borrower_count_by_credit_score
FROM borrowers
GROUP BY credit_score_raw
ORDER BY credit_score_raw;

SELECT COUNT(credit_score_raw) as borrowers_not_in_credit_score_range
FROM borrowers
WHERE credit_score_raw < 300 OR credit_score_raw >850;

SELECT COUNT(credit_score_raw) as borrowers_not_in_credit_score_range, credit_score_raw
FROM borrowers
WHERE credit_score_raw < 300 OR credit_score_raw >850
GROUP BY credit_score_raw;

SELECT SUM(credit_score_raw < 300 OR credit_score_raw > 850) * 100.0 / COUNT(*) AS percent_out_of_range
FROM   borrowers;
-- 600 borrowers 6% have a credit_score_raw outside 300-850. They hold only
-- two values: 999 (368 rows) and -1 (232 rows). Two fixed codes, not scattered values,
-- suggest sentinel values.

SELECT home_ownership, COUNT(*) as borrower_count_by_home_ownership
FROM borrowers
GROUP BY home_ownership
ORDER BY borrower_count_by_home_ownership DESC;
-- FINDING: home ownership split Rent 4,461 / Mortgage 4,276 / Own 1,263 (sums to 10,000).
--   Renters are the largest group  but not a majority. Caveat: the data is synthetic.

SELECT COUNT(*)  AS borrowers, ROUND(AVG(annual_income), 0)  AS avg_income,
ROUND(AVG(employment_length_years), 1) AS avg_tenure,
CASE 
WHEN credit_score_raw < 300 OR credit_score_raw >850 
THEN 'out_of_range' 
ELSE 'valid' 
END AS score_group
FROM borrowers
GROUP BY score_group;
-- out-of-range borrowers average income 40,133 vs 62,342 for the rest, and tenure
--   3.4 vs 6.7 years. 

SELECT AVG(credit_score_raw) AS avg_all_rows,
AVG  (CASE 
WHEN credit_score_raw < 300 OR credit_score_raw >850 
THEN credit_score_raw END) AS avg_valid_only
FROM borrowers;
  
SELECT SUM(borrower_id IS NULL)  AS null_ids, SUM(annual_income IS NULL)  AS null_income,
SUM(credit_score_raw IS NULL)  AS null_credit_score_raw,SUM(employment_length_years IS NULL)   AS null_employment_length_years,
SUM(home_ownership IS NULL)  AS null_home_ownership
FROM borrowers;
--  no NULLs in any column.


SELECT SUM(annual_income = 18000) AS at_min,SUM(annual_income = 250000) AS at_max
FROM   borrowers;

SELECT AVG(credit_score_raw) AS avg_all_rows,
AVG 
(CASE 
WHEN credit_score_raw BETWEEN 999 AND -1 
THEN credit_score_raw END) AS avg_valid_only, AVG(
CASE
WHEN credit_score_raw < 300 OR credit_score_raw > 850 
THEN credit_score_raw END) AS avg_invalid_only
FROM   borrowers;

SELECT SUM(annual_income = 18000)  AS at_min,SUM(annual_income BETWEEN 18001 AND 19000)  AS band_just_above_min,
SUM(annual_income BETWEEN 249000 AND 249999) AS band_just_below_max,SUM(annual_income = 250000) AS at_max
FROM borrowers;


SELECT count(*), count( distinct loan_id)
FROM LOANS;
--  10,540 rows and 10,540 distinct loan_ids. This cannot detect duplicate
--   disbursals because every loan will have a loan_id regardless of the fact that is could be a duplicate.

SELECT min(loan_amount) as Min,max(loan_amount) as Max
FROM LOANS;
-- loan_amount ranges from 1,000 to 40,000.

SELECT MIN(origination_date) AS first_loan,MAX(origination_date) AS last_loan
FROM  loans;
--  origination dates run 2024-01-01 to 2026-09-30, which confirms the 2024-2026 brief.

SELECT loan_intent, COUNT(*) AS loan_intent_count
FROM loans
GROUP BY loan_intent
ORDER BY loan_intent_count DESC;
--  categories are clean and each set sums to 10,540. Intent: Debt Consolidation
--   4,064 / Home Improvement 2,871 / Personal 2,207 / Small Business 1,398. 
 -- Largest intent: Debt Consolidation.
SELECT loan_intent AS category, COUNT(*) AS loan_intent_count, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*))OVER(),2) AS pct_of_loans
FROM loans
GROUP BY loan_intent
ORDER BY loan_intent_count DESC;

SELECT loan_grade, COUNT(*) AS loan_grade_count
FROM loans
GROUP BY loan_grade
ORDER BY loan_grade_count DESC;
--  Grades A-E: 3,447 / 2,396 / 1,870 / 1,232 / 1,595. 
SELECT loan_grade AS category, COUNT(*) AS loan_grade_count, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*))OVER(),2) AS pct_of_loans
FROM loans
GROUP BY loan_grade
ORDER BY loan_grade_count ;

SELECT account_status, COUNT(*) AS account_status_count
FROM  loans
GROUP BY account_status
ORDER BY account_status_count DESC;
-- Status: CURRENT 6,660 / FULLY_PAID 2,632 /
--   CHARGED_OFF 836 / PAST_DUE 412. Largest status: CURRENT 6,660.
SELECT account_status AS category, COUNT(*) AS account_status_count, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_loans
FROM loans
GROUP BY account_status
ORDER BY account_status_count DESC;

SELECT borrower_id, COUNT(*) AS loans_per_borrower
FROM loans
GROUP BY borrower_id
HAVING COUNT(*) > 1
ORDER BY loans_per_borrower DESC;

SELECT COUNT(*) AS borrowers_with_multiple_loans, MAX(loans_per_borrower)  AS max_loans_one_borrower
FROM (SELECT borrower_id, COUNT(*) AS loans_per_borrower
FROM loans
GROUP BY borrower_id
HAVING COUNT(*) > 1
) AS t;
--  539 borrowers hold more than one loan (max 3). This query cannot tell genuine
--   repeat borrowers from double submissions.

SELECT SUM(loan_id IS NULL) AS null_loan_id,SUM(borrower_id IS NULL) AS null_borrower_id,
SUM(loan_amount IS NULL) AS null_loan_amount,SUM(origination_date IS NULL) AS null_origination_date,
SUM(loan_intent IS NULL) AS null_loan_intent,SUM(loan_grade IS NULL) AS null_loan_grade,
SUM(account_status IS NULL) AS null_account_status
FROM loans;
--  no NULLs in any of the 7 columns. Labels, dates and amounts also fall in expected ranges.

SELECT COUNT(*) AS total_rows, MIN(snapshot_date) AS first_snapshot,MAX(snapshot_date) AS last_snapshot
FROM loan_ledger;
--  145,755 rows. Snapshots run 2024-02-29 to 2026-10-31, which sits within the
--   loans range. That is expected because the 2024-2026 brief. Only a per-loan check can show whether a
--   snapshot precedes its own loan's origination.

SELECT days_past_due,COUNT(*) AS row_count, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_rows
FROM loan_ledger
GROUP BY days_past_due
ORDER BY days_past_due;
--  days_past_due: 0 = 93.47%, 30 = 3.25%, 60 = 1.55%, 90 = 0.87%, 120 = 0.59%,
--   above 120 = 0.27%. Each bucket is roughly 30+ the size of the one before it, which is
--   what a real book looks like. These are shares of ROWS (loan-months), not loans.

SELECT MIN(monthly_payment_due) AS min_due,MAX(monthly_payment_due) AS max_due,ROUND(AVG(monthly_payment_due), 2)  AS avg_due,
MIN(amount_paid) AS min_paid,MAX(amount_paid) AS max_paid,ROUND(AVG(amount_paid), 2) AS avg_paid
FROM loan_ledger;
--  (money): monthly_payment_due ranges 34.18 to 3801.77 (avg 699.27); amount_paid ranges
--   0.00 to 40333.33 (avg 723.97).

SELECT SUM(amount_paid = 0) AS zero_payments,SUM(amount_paid > 2 * monthly_payment_due) AS paid_over_double_due,
SUM(monthly_payment_due = 0) AS zero_due
FROM   loan_ledger;
 -- 5681 rows have amount_paid = 0, 2100 have amount_paid above double the amount due, 0 have a zero amount due. 
 -- Large overpayments could be caused by double payment.
 
SELECT MIN(rows_per_loan) AS min_rows,MAX(rows_per_loan) AS max_rows,ROUND(AVG(rows_per_loan), 1)  AS avg_rows,
COUNT(*) AS loans_in_ledger
FROM (
SELECT loan_id, COUNT(*) AS rows_per_loan
FROM loan_ledger
GROUP BY loan_id
) AS t;
-- (rows per loan): 10531 distinct loan_ids in the ledger vs 10,540 in loans.
--  Rows per loan range from 1 to 33 (avg 13.8).

SELECT SUM(snapshot_date IS NULL) AS null_snapshot_date,SUM(loan_id IS NULL) AS null_loan_id,
SUM(monthly_payment_due IS NULL)  AS null_payment_due,SUM(amount_paid IS NULL) AS null_amount_paid,
SUM(days_past_due IS NULL) AS null_days_past_due
FROM loan_ledger;
-- zero NULLs across the five columns.

SELECT days_past_due,COUNT(*) AS row_count,COUNT(DISTINCT loan_id) AS loans_affected
FROM loan_ledger
WHERE days_past_due > 120
GROUP BY days_past_due
ORDER BY days_past_due;



CREATE TABLE audit_log (
check_id INT AUTO_INCREMENT,
audited_table VARCHAR(50) NOT NULL,
rule_description VARCHAR(255) NOT NULL,
records_affected INT NOT NULL,
unit ENUM('rows','loans','borrowers') NOT NULL,
severity ENUM('LOW', 'MEDIUM', 'HIGH') NOT NULL,
PRIMARY KEY(check_id)
);
-- Severity scale (how much the flaw would distort risk results if left in):
-- HIGH   = changes a headline KPI (delinquency, charge-off, exposure) or misstates the status of a loan
-- MEDIUM = distorts a specific analysis or segment, but not the headline numbers
-- LOW    = noise or housekeeping; results are essentially unchanged

SELECT *
FROM loan_ledger ll
LEFT JOIN loans lo
ON ll.loan_id = lo.loan_id
WHERE lo.loan_id IS NULL; 
-- this returned 130 rows of loan ids that doesnt exist in loans

SELECT count(*),COUNT(DISTINCT ll.loan_id) AS orphan_loan_ids
FROM loan_ledger ll
LEFT JOIN loans lo
ON ll.loan_id = lo.loan_id
WHERE lo.loan_id IS NULL; 
-- --130 orphan_rows and 25 distinct orphan loan ids--  
-- Counting distinct IDs gives a more accurate picture of the breadth of the data corruption.

INSERT INTO audit_log (
    audited_table, 
    rule_description, 
    records_affected, 
    unit, 
    severity
) 
SELECT 
    'loan_ledger', 
    'Orphaned ledger rows with no matching loan_id in loans table', 
    COUNT(DISTINCT ll.loan_id), -- Distinct loan count
    'loans',                    -- Unit matches count type
    'LOW'                       -- Low because these 25 rows do not reach KPI
FROM loan_ledger ll 
LEFT JOIN loans lo 
ON ll.loan_id = lo.loan_id 
WHERE lo.loan_id IS NULL;


UPDATE audit_log
SET    rule_description = 'Distinct loan_ids in loan_ledger with no matching loan in loans (130 ledger rows, 25 loan_ids)'
WHERE  check_id = 1;


SELECT COUNT(*) AS offending_rows,COUNT(DISTINCT ll.loan_id) AS offending_loans
FROM loan_ledger ll
INNER JOIN loans lo 
ON ll.loan_id = lo.loan_id
WHERE  ll.snapshot_date < lo.origination_date;

-- count all is 30 while distint count is 15


INSERT INTO audit_log (audited_table, rule_description, records_affected, unit, severity)
SELECT 'loan_ledger',
       'Distinct loans with ledger snapshots dated before their own origination_date (30 ledger rows, 15 loans)',
       COUNT(DISTINCT ll.loan_id),
       'loans',
       'MEDIUM'
FROM   loan_ledger ll
INNER JOIN loans lo ON ll.loan_id = lo.loan_id
WHERE  ll.snapshot_date < lo.origination_date;

SELECT COUNT(*) AS zombie_loans
FROM (
    SELECT   loan_id, MAX(days_past_due) AS max_dpd
    FROM     loan_ledger
    GROUP BY loan_id
    HAVING   MAX(days_past_due) >= 270
) AS m
INNER JOIN loans lo ON lo.loan_id = m.loan_id
WHERE lo.account_status = 'CURRENT';

INSERT INTO audit_log (audited_table, rule_description, records_affected, unit, severity)
SELECT 'loans',
       'Loans with max days_past_due of 270 or more in loan_ledger that are still CURRENT (should be CHARGED_OFF)',
       COUNT(*),
       'loans',
       'HIGH'
FROM (
    SELECT   loan_id, MAX(days_past_due) AS max_dpd
    FROM     loan_ledger
    GROUP BY loan_id
    HAVING   MAX(days_past_due) >= 270
) AS m
INNER JOIN loans lo ON lo.loan_id = m.loan_id
WHERE lo.account_status = 'CURRENT';


SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT   borrower_id, loan_amount, origination_date
    FROM     loans
    GROUP BY borrower_id, loan_amount, origination_date
    HAVING   COUNT(*) > 1
) AS g;
-- 40 duplicate groups

SELECT COUNT(*) AS extra_copies
FROM (
    SELECT loan_id,
 ROW_NUMBER() OVER (
 PARTITION BY borrower_id, loan_amount, origination_date
 ORDER BY loan_id
           ) AS rn
    FROM loans
) AS r
WHERE rn > 1;
-- 40 extra copies

INSERT INTO audit_log (audited_table, rule_description, records_affected, unit, severity)
SELECT 'loans',
       'Extra loan copies sharing borrower_id, loan_amount and origination_date with a lower loan_id (40 groups, 40 extra copies)',
       COUNT(*),
       'loans',
       'HIGH'
FROM (
    SELECT ROW_NUMBER() OVER (
 PARTITION BY borrower_id, loan_amount, origination_date
ORDER BY loan_id
	) AS rn
    FROM loans
) AS r
WHERE rn > 1;

INSERT INTO audit_log (audited_table, rule_description, records_affected, unit, severity)
SELECT 'borrowers',
       'Borrowers with credit_score_raw outside 300-850 (sentinel codes: 999 = 368, -1 = 232)',
       COUNT(*),
       'borrowers',
       'MEDIUM'
FROM   borrowers
WHERE  credit_score_raw < 300 OR credit_score_raw > 850;

select *
from audit_log;


SELECT COUNT(*) AS ledger_rows_on_copies, COUNT(DISTINCT ll.loan_id) AS copies_with_ledger
FROM   loan_ledger ll
INNER JOIN (
    SELECT loan_id
    FROM (
        SELECT loan_id,
ROW_NUMBER() OVER (PARTITION BY borrower_id, loan_amount, origination_date
ORDER BY loan_id) AS rn
        FROM   loans
    ) r
    WHERE rn > 1
) d ON d.loan_id = ll.loan_id;

-- ledger rows on copies are 78 and copies with ledger is 6

SELECT COUNT(*) AS copies_checked, SUM(orig_rows > 0) AS originals_with_ledger, SUM(orig_rows = 0) AS originals_without_ledger
FROM (
    SELECT c.loan_id,
   (SELECT COUNT(*) FROM loan_ledger ll WHERE ll.loan_id = o.loan_id) AS orig_rows
    FROM   (SELECT loan_id, borrower_id, loan_amount, origination_date
     FROM (SELECT loan_id, borrower_id, loan_amount, origination_date,
     ROW_NUMBER() OVER (PARTITION BY borrower_id, loan_amount, origination_date
                                            ORDER BY loan_id) AS rn
                  FROM loans) r
            WHERE rn > 1) c
    INNER JOIN loans o
            ON  o.borrower_id      = c.borrower_id
            AND o.loan_amount      = c.loan_amount
            AND o.origination_date = c.origination_date
            AND o.loan_id          < c.loan_id
    WHERE c.loan_id IN (SELECT loan_id FROM loan_ledger)
) x;

-- copies checked =6, originals with ledger =6,originals without ledger =0

SELECT COUNT(*) AS rows_above_120, COUNT(DISTINCT ll.loan_id) AS zombie_loans
FROM   loan_ledger ll
INNER JOIN loans lo 
ON lo.loan_id = ll.loan_id
WHERE  lo.account_status = 'CURRENT' AND  ll.days_past_due > 120;
  
-- rows above 120 is 379 and zombie loans is 30


CREATE TABLE quarantine_loans LIKE loans;
ALTER TABLE quarantine_loans ADD COLUMN reason VARCHAR(100) NOT NULL;

INSERT INTO quarantine_loans
SELECT loan_id, borrower_id, loan_amount, origination_date,
       loan_intent, loan_grade, account_status,
       'duplicate disbursal (kept lowest loan_id)'
FROM (
    SELECT l.*,ROW_NUMBER() OVER (PARTITION BY borrower_id, loan_amount, origination_date
ORDER BY loan_id) AS rn
FROM   loans l
) r
WHERE rn > 1;

CREATE TABLE quarantine_loan_ledger LIKE loan_ledger;
ALTER TABLE quarantine_loan_ledger ADD COLUMN reason VARCHAR(100) NOT NULL;

INSERT INTO quarantine_loan_ledger
SELECT snapshot_date, loan_id, monthly_payment_due, amount_paid, days_past_due, reason
FROM (
    SELECT ll.*,
           CASE
               WHEN lo.loan_id IS NULL                          THEN 'orphan: no matching loan'
               WHEN ll.snapshot_date < lo.origination_date      THEN 'snapshot before origination'
               WHEN q.loan_id IS NOT NULL                       THEN 'ledger rows of duplicate loan copy'
               WHEN lo.account_status = 'CURRENT'
                    AND ll.days_past_due > 120                  THEN 'post-charge-off ageing'
           END AS reason
    FROM   loan_ledger ll
    LEFT JOIN loans lo            ON lo.loan_id = ll.loan_id
    LEFT JOIN quarantine_loans q  ON q.loan_id  = ll.loan_id
) x
WHERE reason IS NOT NULL;

SELECT reason, COUNT(*) AS rows_quarantined
FROM   quarantine_loan_ledger
GROUP BY reason;

CREATE TABLE clean_borrowers AS
SELECT borrower_id, annual_income,
CASE WHEN credit_score_raw BETWEEN 300 AND 850 THEN credit_score_raw END AS credit_score,
(credit_score_raw NOT BETWEEN 300 AND 850)  AS score_is_missing, employment_length_years, home_ownership
FROM   borrowers;

ALTER TABLE clean_borrowers ADD PRIMARY KEY (borrower_id);

CREATE TABLE clean_loans AS
SELECT lo.loan_id, lo.borrower_id, lo.loan_amount, lo.origination_date, lo.loan_intent, lo.loan_grade,
CASE WHEN z.loan_id IS NOT NULL THEN 'CHARGED_OFF' ELSE lo.account_status END AS account_status,
(z.loan_id IS NOT NULL) AS status_corrected
FROM   loans lo
LEFT JOIN (
    SELECT   loan_id
    FROM     loan_ledger
    GROUP BY loan_id
    HAVING   MAX(days_past_due) >= 270
) z ON z.loan_id = lo.loan_id AND lo.account_status = 'CURRENT'
WHERE  NOT EXISTS (SELECT 1 FROM quarantine_loans q WHERE q.loan_id = lo.loan_id);

ALTER TABLE clean_loans ADD PRIMARY KEY (loan_id);

CREATE TABLE clean_loan_ledger AS
SELECT snapshot_date, loan_id, monthly_payment_due, amount_paid, days_past_due
FROM (
    SELECT ll.*,
           CASE
               WHEN lo.loan_id IS NULL THEN 'orphan: no matching loan'
               WHEN ll.snapshot_date < lo.origination_date  THEN 'snapshot before origination'
               WHEN q.loan_id IS NOT NULL THEN 'ledger rows of duplicate loan copy'
               WHEN lo.account_status = 'CURRENT' AND ll.days_past_due > 120 THEN 'post-charge-off ageing'
           END AS reason
    FROM   loan_ledger ll
    LEFT JOIN loans lo
    ON lo.loan_id = ll.loan_id
    LEFT JOIN quarantine_loans q 
    ON q.loan_id  = ll.loan_id
) x
WHERE reason IS NULL;

CREATE INDEX idx_clean_ledger_loan_date ON clean_loan_ledger (loan_id, snapshot_date);


-- expected(clean borrowers-10000,clean loans-10500,clean loan ledger-145138)
-- actual result(clean borrowers-10000,clean loans-10500,clean loan ledger-145138)

SELECT 'clean_borrowers' AS tbl, COUNT(*) AS n FROM clean_borrowers
UNION ALL SELECT 'clean_loans',       COUNT(*) FROM clean_loans
UNION ALL SELECT 'clean_loan_ledger', COUNT(*) FROM clean_loan_ledger;

SELECT SUM(score_is_missing)  
FROM clean_borrowers;

SELECT SUM(status_corrected)  
FROM clean_loans;

-- score is missing-600,status_corrected-30

SELECT 'borrowers' AS tbl,
       (SELECT COUNT(*) FROM borrowers)        AS raw_rows,
       0                                       AS quarantined,
       (SELECT COUNT(*) FROM clean_borrowers)  AS clean_rows,
       (SELECT COUNT(*) FROM borrowers) - 0
         - (SELECT COUNT(*) FROM clean_borrowers) AS difference
UNION ALL
SELECT 'loans',
       (SELECT COUNT(*) FROM loans),
       (SELECT COUNT(*) FROM quarantine_loans),
       (SELECT COUNT(*) FROM clean_loans),
       (SELECT COUNT(*) FROM loans)
         - (SELECT COUNT(*) FROM quarantine_loans)
         - (SELECT COUNT(*) FROM clean_loans)
UNION ALL
SELECT 'loan_ledger',
       (SELECT COUNT(*) FROM loan_ledger),
       (SELECT COUNT(*) FROM quarantine_loan_ledger),
       (SELECT COUNT(*) FROM clean_loan_ledger),
       (SELECT COUNT(*) FROM loan_ledger)
         - (SELECT COUNT(*) FROM quarantine_loan_ledger)
         - (SELECT COUNT(*) FROM clean_loan_ledger);
--  every raw row is accounted for, with a difference of 0 in all three tables.
--   This shows that cleaning neither lost nor double-counted any rows.

SELECT '3.1 scores out of range' AS chk, COUNT(*) AS violations
FROM   clean_borrowers
WHERE  credit_score < 300 OR credit_score > 850
UNION ALL
SELECT '3.2 orphaned ledger rows', COUNT(*)
FROM   clean_loan_ledger ll
LEFT JOIN clean_loans lo ON lo.loan_id = ll.loan_id
WHERE  lo.loan_id IS NULL
UNION ALL
SELECT '3.3 snapshot before origination', COUNT(*)
FROM   clean_loan_ledger ll
INNER JOIN clean_loans lo ON lo.loan_id = ll.loan_id
WHERE  ll.snapshot_date < lo.origination_date
UNION ALL
SELECT '3.4 high DPD not charged off', COUNT(DISTINCT ll.loan_id)
FROM   clean_loan_ledger ll
INNER JOIN clean_loans lo ON lo.loan_id = ll.loan_id
WHERE  ll.days_past_due >= 120
  AND  lo.account_status <> 'CHARGED_OFF'
UNION ALL
SELECT '3.5 duplicate disbursals', COUNT(*)
FROM (
    SELECT   borrower_id, loan_amount, origination_date
    FROM     clean_loans
    GROUP BY borrower_id, loan_amount, origination_date
    HAVING   COUNT(*) > 1
) d;

-- (re-run of the five checks on the clean tables): all five return 0 violations.

CREATE VIEW v_ledger_features AS
SELECT ll.loan_id, ll.snapshot_date, ll.monthly_payment_due, ll.amount_paid, ll.days_past_due,
       LAG(ll.days_past_due) OVER (PARTITION BY ll.loan_id ORDER BY ll.snapshot_date) AS prev_month_dpd,
       PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM ll.snapshot_date),
                   EXTRACT(YEAR_MONTH FROM lo.origination_date))                      AS months_on_book,
       CONCAT(YEAR(lo.origination_date), '-Q', QUARTER(lo.origination_date))          AS vintage,
       lo.loan_grade, lo.loan_intent, lo.account_status, lo.loan_amount,
       CASE WHEN b.credit_score IS NULL THEN 'Unknown'
            WHEN b.credit_score < 580 THEN 'Poor'
            WHEN b.credit_score < 670 THEN 'Fair'
            WHEN b.credit_score < 740 THEN 'Good'
            ELSE 'Excellent'
       END AS score_band
FROM   clean_loan_ledger ll
INNER JOIN clean_loans lo
ON lo.loan_id  = ll.loan_id
INNER JOIN clean_borrowers b  
ON b.borrower_id  = lo.borrower_id;

SELECT COUNT(*) 
FROM v_ledger_features;

SELECT MIN(months_on_book), MAX(months_on_book), SUM(months_on_book < 1) AS bad_age
FROM v_ledger_features;

SELECT SUM(prev_month_dpd IS NULL) AS first_rows, COUNT(DISTINCT loan_id) AS loans
FROM v_ledger_features;

SELECT score_band, COUNT(*) 
FROM v_ledger_features 
GROUP BY score_band;
-- Unknown holds 8,828 ledger rows (6.1%), which is larger than Poor (7,028). 
-- Those borrowers have lower incomes and shorter tenures, so if they had real scores, many would probably land in Poor or Fair.

CREATE VIEW v_kpi_delinquency AS
SELECT snapshot_date, COUNT(*) AS loan_months, SUM(days_past_due >= 30)  AS delinquent_loan_months,
ROUND(SUM(days_past_due >= 30) * 100.0 / COUNT(*), 2) AS delinquency_rate_pct
FROM v_ledger_features
GROUP BY snapshot_date;

SELECT SUM(loan_months)AS total_loan_months, COUNT(*) AS months, MIN(delinquency_rate_pct) AS min_rate, MAX(delinquency_rate_pct) AS max_rate
FROM v_kpi_delinquency;
-- KPI 1 Delinquency rate: loan-months at 30+ DPD / all loan-months, by snapshot month

CREATE VIEW v_kpi_chargeoff_by_grade AS
SELECT loan_grade, COUNT(*) AS loans, SUM(account_status = 'CHARGED_OFF') AS charged_off,
ROUND(SUM(account_status = 'CHARGED_OFF') * 100.0 / COUNT(*), 2) AS chargeoff_rate_pct
FROM clean_loans
GROUP BY loan_grade;

CREATE VIEW v_kpi_chargeoff_by_intent AS
SELECT loan_intent,COUNT(*) AS loans,SUM(account_status = 'CHARGED_OFF') AS charged_off,
 ROUND(SUM(account_status = 'CHARGED_OFF') * 100.0 / COUNT(*), 2) AS chargeoff_rate_pct
FROM   clean_loans
GROUP BY loan_intent;

SELECT 'by_grade' AS source, SUM(loans) AS loans, SUM(charged_off) AS charged_off
FROM   v_kpi_chargeoff_by_grade
UNION ALL
SELECT 'by_intent', SUM(loans), SUM(charged_off)
FROM   v_kpi_chargeoff_by_intent
UNION ALL
SELECT 'clean_loans', COUNT(*), SUM(account_status = 'CHARGED_OFF')
FROM   clean_loans;
-- KPI 2 Charge-off rate: charged-off loans / all loans, by grade and by intent (unit: loans)

CREATE VIEW v_kpi_collection_by_band AS
SELECT score_band, ROUND(SUM(LEAST(amount_paid, monthly_payment_due)) * 100.0 / SUM(monthly_payment_due), 2) AS collection_ratio_pct
FROM v_ledger_features
GROUP BY score_band;

SELECT COUNT(*) AS bands, MIN(collection_ratio_pct) AS min_ratio, MAX(collection_ratio_pct) AS max_ratio
FROM v_kpi_collection_by_band;
-- KPI 3 Collection ratio: SUM(LEAST(amount_paid, monthly_payment_due)) / SUM(monthly_payment_due), by score band

CREATE VIEW v_kpi_roll_rate AS
SELECT prev_month_dpd AS from_bucket, COUNT(*) AS loan_months,ROUND(SUM(days_past_due = prev_month_dpd + 30) * 100.0 / COUNT(*), 1) AS roll_forward_pct,
ROUND(SUM(days_past_due = prev_month_dpd) * 100.0 / COUNT(*), 1) AS stay_pct, ROUND(SUM(days_past_due <  prev_month_dpd) * 100.0 / COUNT(*), 1) AS cure_pct
FROM v_ledger_features
WHERE  prev_month_dpd IS NOT NULL
  AND  prev_month_dpd IN (0, 30, 60, 90)
GROUP BY prev_month_dpd;

-- each bucket's three percentages adds up to 100
SELECT from_bucket, loan_months, roll_forward_pct + stay_pct + cure_pct AS total_pct
FROM v_kpi_roll_rate
ORDER BY from_bucket;

-- the view covers every eligible loan-month
SELECT (SELECT SUM(loan_months) FROM v_kpi_roll_rate) AS in_view,
       (SELECT COUNT(*) FROM v_ledger_features
        WHERE prev_month_dpd IN (0, 30, 60, 90)) AS eligible_rows;
-- KPI 4 Roll rate: loan-months moving from bucket X to X+30 / loan-months in bucket X

CREATE VIEW v_loan_vintage AS
SELECT lo.loan_id, CONCAT(YEAR(lo.origination_date), '-Q', QUARTER(lo.origination_date)) AS vintage,
PERIOD_DIFF(202610, EXTRACT(YEAR_MONTH FROM lo.origination_date))  AS obs_months,
CASE WHEN lo.account_status = 'CHARGED_OFF' THEN co.co_mob END AS co_mob
FROM clean_loans lo
LEFT JOIN (SELECT loan_id, MAX(months_on_book) AS co_mob
           FROM   v_ledger_features
           GROUP BY loan_id) co ON co.loan_id = lo.loan_id;

CREATE VIEW v_kpi_vintage AS
SELECT v.vintage, k.mob, COUNT(*) AS loans_observed, SUM(COALESCE(v.co_mob <= k.mob, 0)) AS charged_off_by_k,
ROUND(SUM(COALESCE(v.co_mob <= k.mob, 0)) * 100.0 / COUNT(*), 2) AS cum_chargeoff_pct
FROM v_loan_vintage v
JOIN  (SELECT 3 AS mob UNION ALL SELECT 6 UNION ALL SELECT 9
       UNION ALL SELECT 12 UNION ALL SELECT 18) k
  ON v.obs_months >= k.mob
GROUP BY v.vintage, k.mob;

-- one row per loan, and every charged-off loan has an age
SELECT COUNT(*) AS loans_in_view, COUNT(co_mob) AS charged_off_with_age
FROM v_loan_vintage;

SELECT vintage, mob, loans_observed, cum_chargeoff_pct,
cum_chargeoff_pct - LAG(cum_chargeoff_pct)
OVER (PARTITION BY vintage ORDER BY mob) AS change_vs_prev
FROM v_kpi_vintage
ORDER BY vintage, mob;
-- KPI 5 Vintage curve: loans charged off by month k / loans observed for at least k months


CREATE OR REPLACE VIEW v_vintage_size AS
SELECT vintage, COUNT(*) AS vintage_loans
FROM   v_loan_vintage
GROUP BY vintage;

CREATE OR REPLACE VIEW v_kpi_vintage AS
SELECT v.vintage, k.mob, COUNT(*) AS loans_observed, SUM(COALESCE(v.co_mob <= k.mob, 0)) AS charged_off_by_k,
ROUND(SUM(COALESCE(v.co_mob <= k.mob, 0)) * 100.0 / COUNT(*), 2) AS cum_chargeoff_pct
FROM   v_loan_vintage v
JOIN   v_vintage_size s ON s.vintage = v.vintage
JOIN  (SELECT 3 AS mob UNION ALL SELECT 6 UNION ALL SELECT 9
       UNION ALL SELECT 12 UNION ALL SELECT 18) k
  ON   v.obs_months >= k.mob
GROUP BY v.vintage, k.mob, s.vintage_loans
HAVING COUNT(*) = s.vintage_loans;

SELECT COUNT(*) 
FROM v_kpi_vintage;

SELECT vintage, mob, loans_observed, cum_chargeoff_pct
FROM   v_kpi_vintage
ORDER BY vintage, mob;

SELECT vintage, COUNT(*) AS vintage_loans
FROM   v_loan_vintage
GROUP BY vintage
ORDER BY vintage;

SELECT * 
FROM v_kpi_delinquency
ORDER BY snapshot_date;

SELECT * 
FROM v_kpi_chargeoff_by_grade
ORDER BY loan_grade;

SELECT * 
FROM v_kpi_chargeoff_by_intent 
ORDER BY chargeoff_rate_pct DESC;

SELECT * 
FROM v_kpi_collection_by_band  
ORDER BY collection_ratio_pct DESC;

SELECT * 
FROM v_kpi_roll_rate
ORDER BY from_bucket;






