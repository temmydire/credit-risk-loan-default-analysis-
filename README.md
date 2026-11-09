# Credit Risk and Loan Default Analysis Using SQL

## Project Overview

This project focuses on analysing borrower profiles, loan performance, repayment behaviour and credit risk using SQL (MySQL).

The objective was to assess the quality of a loan portfolio, identify data integrity issues, investigate delinquency patterns, and develop key risk performance indicators that can support better lending and credit risk management decisions.

Using three relational datasets — Borrowers, Loans and Loan Ledger — I performed data exploration, data quality auditing, data cleaning, and risk analysis to uncover patterns that could affect loan portfolio performance.

**Tools Used:** MySQL 

**Project Type:** Data Cleaning, Exploratory Data Analysis (EDA), Data Quality Auditing and Credit Risk Analytics.

**Dataset:** Synthetic credit risk and loan repayment data.

---

## Business Problem

Financial institutions need to monitor their loan portfolios to identify borrowers who may be struggling with repayments, detect potentially problematic accounts, and understand the factors associated with loan defaults.

However, unreliable data can lead to inaccurate risk assessments and misleading portfolio performance metrics.

This project addresses the following questions:

- How reliable and consistent is the underlying loan portfolio data?
- Are there duplicate loan records or inconsistencies in repayment histories?
- How does delinquency vary across loan repayment periods?
- Which loan grades and loan purposes experience higher charge-off rates?
- How effective are collections across borrower credit score categories?
- How do loans transition between delinquency stages?
- How does charge-off performance change across loan origination vintages?

---

## Dataset Description

The project uses three relational tables:

| Table | Description |
|---|---|
| borrowers | Borrower financial and demographic information |
| loans | Loan details, origination information and account status |
| loan_ledger | Monthly repayment records and days past due |

### Key Columns

**Borrowers**
- borrower_id
- annual_income
- credit_score_raw
- employment_length_years
- home_ownership

**Loans**
- loan_id
- borrower_id
- loan_amount
- origination_date
- loan_intent
- loan_grade
- account_status

**Loan Ledger**
- snapshot_date
- loan_id
- monthly_payment_due
- amount_paid
- days_past_due

---

## Project Workflow

### 1. Database Creation and Data Loading

- Created a MySQL database named `Credit_Risk_Project`.
- Designed three relational tables.
- Established primary key and foreign key relationships where applicable.
- Imported the CSV datasets using `LOAD DATA LOCAL INFILE`.
- Reconciled imported row counts against the source files.

### 2. Exploratory Data Analysis (EDA)

Explored borrower demographics, financial characteristics and loan portfolio composition.

Analyses included:
- Borrower income distribution.
- Employment tenure.
- Credit score distribution and invalid score values.
- Home ownership distribution.
- Loan amounts and origination dates.
- Loan intent and grade distribution.
- Loan account status distribution.
- Repayment behaviour and days past due.

### 3. Data Quality Auditing

Investigated potential data integrity issues, including:

- Invalid credit scores outside the 300–850 range.
- Duplicate loan disbursements.
- Orphaned loan ledger records.
- Repayment snapshots occurring before loan origination.
- Loans with severe delinquency but an inconsistent CURRENT account status.
- Missing values and unusual repayment amounts.

Created an `audit_log` table to document identified issues, the number of affected records, the measurement unit and severity.

### 4. Data Cleaning and Validation

Applied data cleaning techniques while preserving questionable records for audit purposes.

Key activities:
- Identified invalid credit score codes and represented them as missing in the cleaned borrower table.
- Identified and quarantined suspected duplicate loan records.
- Isolated orphaned ledger records.
- Quarantined repayment records occurring before loan origination.
- Corrected certain loan statuses based on severe delinquency history.
- Created separate cleaned tables for borrowers, loans and loan ledger records.
- Re-ran data quality checks to validate the cleaned datasets.

Created the following cleaned tables:

- `clean_borrowers`
- `clean_loans`
- `clean_loan_ledger`

### 5. Credit Risk Analysis and KPI Development

Created SQL views to calculate important credit risk indicators.

| KPI | Description |
|---|---|
| Delinquency Rate | Percentage of loan-month records with 30 or more days past due |
| Charge-off Rate | Percentage of loans charged off, analysed by loan grade and loan intent |
| Collection Ratio | Percentage of scheduled payment amounts collected, grouped by credit score band |
| Roll Rate | Movement of loans between delinquency buckets over consecutive snapshots |
| Vintage Analysis | Cumulative charge-off performance at different months on book across origination cohorts |

Additional analysis included:
- Borrower credit score segmentation.
- Loan performance by grade.
- Loan performance by purpose.
- Repayment trends.
- Loan ageing and delinquency progression.

---

## Key Findings

The following findings were documented during the SQL analysis:

### Data Quality Findings

- Identified 600 borrowers (6%) with invalid credit score values outside the accepted 300–850 range.
- The invalid scores consisted of two sentinel values: `999` (368 records) and `-1` (232 records).
- Identified 40 suspected duplicate loan copies.
- Identified 130 orphaned loan ledger records belonging to 25 distinct loan IDs.
- Identified 30 ledger records dated before the origination dates of 15 loans.
- Identified 30 loans classified as CURRENT despite having reached at least 270 days past due.

### Portfolio Findings

- Debt Consolidation was the most common loan purpose, accounting for 4,064 loans.
- Loan grades A and E accounted for 3,447 and 1,595 loans respectively.
- CURRENT was the largest account status category, with 6,660 loans.
- A total of 539 borrowers had multiple loans, with a maximum of three loans per borrower.

### Data Cleaning Results

| Dataset | Raw Records | Clean Records |
|---|---:|---:|
| Borrowers | 10,000 | 10,000 |
| Loans | 10,540 | 10,500 |
| Loan Ledger | 145,755 | 145,138 |

The cleaning process also flagged 600 borrower credit scores as missing in the cleaned dataset and corrected 30 loan account statuses.

All five final validation checks returned zero violations.

Every raw record was accounted for through the cleaning and quarantine process, with no unexplained row-count differences.

---

## SQL Skills Demonstrated

This project demonstrates practical application of:

- Database creation and relational table design.
- Data ingestion and validation.
- Aggregate functions: `COUNT()`, `SUM()`, `AVG()`, `MIN()` and `MAX()`.
- Conditional logic using `CASE WHEN`.
- Filtering and grouping using `WHERE`, `GROUP BY` and `HAVING`.
- Joins: `INNER JOIN` and `LEFT JOIN`.
- Subqueries and derived tables.
- Window functions: `ROW_NUMBER()` and `LAG()`.
- Index creation and query examination using `EXPLAIN`.
- SQL views for reusable analytical queries.
- Data quality auditing and reconciliation.

---

## Business Recommendations

Based on the analysis framework and identified data quality issues, the following actions are recommended:

1. **Strengthen Data Quality Controls:** Introduce validation rules to prevent invalid credit scores, duplicate loan submissions and inconsistent repayment records from entering the loan management system.

2. **Improve Delinquency Monitoring:** Monitor loans approaching critical delinquency thresholds and investigate accounts whose repayment history conflicts with their reported account status.

3. **Monitor Loan Performance by Grade:** Regularly compare charge-off rates across loan grades to identify segments requiring closer risk assessment.

4. **Improve Collections Monitoring:** Use collection ratios and roll-rate analysis to identify delinquency segments where collection efforts may need improvement.

5. **Track Loan Vintage Performance:** Monitor charge-off trends across origination cohorts to identify changes in portfolio quality over time.

---

## Project Limitations

- The dataset is synthetic and does not represent actual financial institution records.
- Invalid credit scores were treated as missing rather than replaced with estimated values.
- Suspected duplicate disbursements were identified using borrower ID, loan amount and origination date. These records require business verification before being treated as confirmed duplicates.
- The analysis is descriptive and does not constitute a predictive credit scoring or loan default machine learning model.

---

## Conclusion

This project demonstrates how SQL can be used to transform raw credit risk data into structured, validated and analysis-ready datasets.

By combining data quality auditing, data cleaning, advanced SQL queries and credit risk KPIs, I developed a framework for examining loan portfolio performance, identifying potential data integrity issues and monitoring repayment behaviour.

The project strengthened my practical SQL skills and deepened my understanding of credit risk analytics, particularly delinquency monitoring, loan charge-offs, collections and vintage analysis.
