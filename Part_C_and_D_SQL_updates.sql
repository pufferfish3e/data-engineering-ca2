-- ST1501 CA2: SQL updates for Part c verification and Part d Analyses 7-8
USE CA2DW2B2104;

-- ================================================================
-- PART C: ETL VERIFICATION QUERIES
-- Add these to the end of DW_insert.sql.
-- ================================================================

-- C1. Row-count reconciliation
SELECT
    (SELECT COUNT(*)
       FROM CA22B2104.Loan
      WHERE ReturnDatetime IS NOT NULL) AS oltp_completed_loans,
    (SELECT COUNT(*) FROM FactLoan) AS dw_fact_loans,
    (SELECT COUNT(*) FROM CA22B2104.Member) AS oltp_members,
    (SELECT COUNT(*) FROM DimMember) AS dw_members,
    (SELECT COUNT(*) FROM CA22B2104.Book) AS oltp_books,
    (SELECT COUNT(*) FROM DimBook) AS dw_books,
    (SELECT COUNT(*) FROM CA22B2104.Staff) AS oltp_staff,
    (SELECT COUNT(*) FROM DimStaff) AS dw_staff,
    (SELECT COUNT(*) FROM DimDate) AS dw_dates;

-- Expected results from the current load:
-- completed loans / FactLoan = 12,343 / 12,343
-- Member / DimMember       = 301 / 301
-- Book / DimBook           = 500 / 500
-- Staff / DimStaff         = 51 / 51
-- DimDate                  = 2,557

-- C2. Measure reconciliation
SELECT
    (SELECT SUM(DATEDIFF(DATE(ReturnDatetime), DATE(StartDatetime)))
       FROM CA22B2104.Loan
      WHERE ReturnDatetime IS NOT NULL) AS oltp_total_duration_days,
    (SELECT SUM(LoanDurationDays)
       FROM FactLoan) AS dw_total_duration_days;

-- Expected result: 108,801 days on both sides.

-- C3. Complete orphan-key check across every dimension role
SELECT COUNT(*) AS orphan_fact_rows
FROM FactLoan AS f
LEFT JOIN DimMember AS dm
       ON dm.MemberKey = f.MemberKey
LEFT JOIN DimStaff AS ds
       ON ds.StaffKey = f.StaffKey
LEFT JOIN DimBook AS db
       ON db.BookKey = f.BookKey
LEFT JOIN DimDate AS bd
       ON bd.DateKey = f.BorrowDateKey
LEFT JOIN DimDate AS rd
       ON rd.DateKey = f.ReturnDateKey
WHERE dm.MemberKey IS NULL
   OR ds.StaffKey IS NULL
   OR db.BookKey IS NULL
   OR bd.DateKey IS NULL
   OR rd.DateKey IS NULL;

-- Expected result: 0.

-- C4. Date-dimension range and row count
SELECT
    MIN(FullDate) AS first_date,
    MAX(FullDate) AS last_date,
    COUNT(*) AS date_rows
FROM DimDate;

-- Expected result: 2020-01-01, 2026-12-31, 2,557.


-- ================================================================
-- PART D: ANALYSIS 7
-- Staff workload by department and employment type
-- Add this query to DW_query.sql.
-- ================================================================
SELECT
    ds.Department,
    ds.EmploymentType,
    COUNT(*) AS CompletedLoans,
    ROUND(AVG(f.LoanDurationDays), 2) AS AvgLoanDurationDays,
    ROUND(100.0 * AVG(f.IsLate), 2) AS LateReturnRatePct
FROM FactLoan AS f
JOIN DimStaff AS ds
  ON ds.StaffKey = f.StaffKey
GROUP BY
    ds.Department,
    ds.EmploymentType
ORDER BY
    CompletedLoans DESC,
    ds.Department,
    ds.EmploymentType;


-- ================================================================
-- PART D: ANALYSIS 8
-- Severity of late returns
-- Add this query to DW_query.sql.
-- ================================================================
WITH ReturnBands AS (
    SELECT
        CASE
            WHEN DaysBeforeDue >= 0 THEN 'On time or early'
            WHEN DaysBeforeDue BETWEEN -3 AND -1 THEN '1-3 days late'
            WHEN DaysBeforeDue BETWEEN -7 AND -4 THEN '4-7 days late'
            ELSE '8+ days late'
        END AS ReturnTimingBand,
        LoanDurationDays
    FROM FactLoan
),
BandSummary AS (
    SELECT
        ReturnTimingBand,
        COUNT(*) AS LoanCount,
        ROUND(AVG(LoanDurationDays), 2) AS AvgLoanDurationDays
    FROM ReturnBands
    GROUP BY ReturnTimingBand
)
SELECT
    ReturnTimingBand,
    LoanCount,
    ROUND(100.0 * LoanCount / SUM(LoanCount) OVER (), 2) AS SharePct,
    AvgLoanDurationDays
FROM BandSummary
ORDER BY CASE ReturnTimingBand
    WHEN 'On time or early' THEN 1
    WHEN '1-3 days late' THEN 2
    WHEN '4-7 days late' THEN 3
    ELSE 4
END;
