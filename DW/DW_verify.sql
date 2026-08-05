-- ST1501 CA2: SQL updates for Part c verification and Part d Analyses 7-8
USE CA2DW2B2104;

-- ================================================================
-- PART C: ETL VERIFICATION QUERIES
-- Add these to the end of DW_insert.sql.
-- ================================================================

-- C1. Row-count reconciliation
-- Compare source and warehouse counts in one result row. FactLoan excludes the
-- open loan, so it is compared only with OLTP loans having a return date.
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
-- Recalculate total completed-loan duration in OLTP and compare it with the
-- transformed FactLoan measure; matching totals validate the ETL calculation.
SELECT
    (SELECT SUM(DATEDIFF(DATE(ReturnDatetime), DATE(StartDatetime)))
       FROM CA22B2104.Loan
      WHERE ReturnDatetime IS NOT NULL) AS oltp_total_duration_days,
    (SELECT SUM(LoanDurationDays)
       FROM FactLoan) AS dw_total_duration_days;

-- Expected result: 108,801 days on both sides.

-- C3. Complete orphan-key check across every dimension
-- LEFT JOIN preserves every fact row. Any NULL dimension key after the joins
-- identifies a foreign key that did not resolve during the warehouse load.
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
WHERE dm.MemberKey IS NULL
   OR ds.StaffKey IS NULL
   OR db.BookKey IS NULL
   OR bd.DateKey IS NULL;

-- Expected result: 0.

-- C4. Date-dimension range and row count
-- Confirm the generated calendar includes every required date, including dates
-- beyond the final borrow date that are needed for due and return-date coverage.
SELECT
    MIN(FullDate) AS first_date,
    MAX(FullDate) AS last_date,
    COUNT(*) AS date_rows
FROM DimDate;

-- Expected result: 2020-01-01, 2026-12-31, 2,557.


