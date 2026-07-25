-- ST1501 CA2 Task d) - Data warehouse analytics (8 queries, group of 4)
-- MySQL 8.0+ is required for the window function in Query 8.
USE CA2DW2B2104;

-- ============================================================================
-- Query 1 | Monthly loan volume and average duration
-- ============================================================================
SELECT
    d.Year,
    d.MonthName,
    COUNT(*) AS TotalLoans,
    ROUND(AVG(f.LoanDurationDays), 2) AS AvgDurationDays
FROM FactLoan AS f
JOIN DimDate AS d
    ON f.BorrowDateKey = d.DateKey
GROUP BY
    d.Year,
    d.Month,
    d.MonthName
ORDER BY
    d.Year,
    d.Month;

-- ============================================================================
-- Query 2 | Borrowing pattern by day of week
-- ============================================================================
SELECT
    d.DayOfWeek,
    COUNT(*) AS TotalLoans,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM FactLoan), 2) AS PctOfAllLoans
FROM FactLoan AS f
JOIN DimDate AS d
    ON f.BorrowDateKey = d.DateKey
GROUP BY
    d.DayOfWeek,
    d.IsWeekend
ORDER BY
    TotalLoans DESC;

-- ============================================================================
-- Query 3 | Genre popularity and borrowing intensity per title
-- ============================================================================
SELECT
    b.Genre,
    COUNT(*) AS TotalLoans,
    COUNT(DISTINCT b.BookKey) AS DistinctBooks,
    ROUND(COUNT(*) / COUNT(DISTINCT b.BookKey), 1) AS LoansPerBook,
    ROUND(AVG(f.LoanDurationDays), 2) AS AvgDurationDays
FROM FactLoan AS f
JOIN DimBook AS b
    ON f.BookKey = b.BookKey
GROUP BY
    b.Genre
ORDER BY
    TotalLoans DESC;

-- ============================================================================
-- Query 4 | Members with the highest and lowest borrowing activity
-- ============================================================================
WITH member_activity AS (
    SELECT
        m.MemberID,
        m.Name,
        m.TierName,
        COUNT(*) AS TotalLoans,
        SUM(f.LoanDurationDays) AS TotalDurationDays
    FROM FactLoan AS f
    JOIN DimMember AS m
        ON f.MemberKey = m.MemberKey
    GROUP BY
        m.MemberKey,
        m.MemberID,
        m.Name,
        m.TierName
)
(
    SELECT
        'Top 5' AS MemberGroup,
        ma.MemberID,
        ma.Name,
        ma.TierName,
        ma.TotalLoans,
        ma.TotalDurationDays
    FROM member_activity AS ma
    ORDER BY
        ma.TotalLoans DESC
    LIMIT 5
)
UNION ALL
(
    SELECT
        'Bottom 5' AS MemberGroup,
        ma.MemberID,
        ma.Name,
        ma.TierName,
        ma.TotalLoans,
        ma.TotalDurationDays
    FROM member_activity AS ma
    ORDER BY
        ma.TotalLoans ASC
    LIMIT 5
);

-- ============================================================================
-- Query 5 | Loan duration and late-return rate by membership tier
-- ============================================================================
SELECT
    m.TierName,
    COUNT(*) AS TotalLoans,
    SUM(f.IsLate) AS LateReturns,
    ROUND(SUM(f.IsLate) * 100.0 / COUNT(*), 2) AS LateReturnRatePct,
    ROUND(AVG(f.LoanDurationDays), 2) AS AvgDurationDays
FROM FactLoan AS f
JOIN DimMember AS m
    ON f.MemberKey = m.MemberKey
GROUP BY
    m.TierName,
    m.TierLevel
ORDER BY
    m.TierLevel;

-- ============================================================================
-- Query 6 | Monthly demand for Children and Young Adult genres
-- ============================================================================
SELECT
    b.Genre,
    d.Month,
    d.MonthName,
    COUNT(*) AS TotalLoans
FROM FactLoan AS f
JOIN DimBook AS b
    ON f.BookKey = b.BookKey
JOIN DimDate AS d
    ON f.BorrowDateKey = d.DateKey
WHERE b.Genre IN ('Children', 'Young Adult')
GROUP BY
    b.Genre,
    d.Month,
    d.MonthName
ORDER BY
    b.Genre,
    d.Month;

-- ============================================================================
-- Query 7 | Staff workload by department and employment type
-- ============================================================================
SELECT
    s.Department,
    s.EmploymentType,
    COUNT(*) AS CompletedLoans,
    ROUND(AVG(f.LoanDurationDays), 2) AS AvgLoanDurationDays,
    ROUND(100.0 * AVG(f.IsLate), 2) AS LateReturnRatePct
FROM FactLoan AS f
JOIN DimStaff AS s
    ON f.StaffKey = s.StaffKey
GROUP BY
    s.Department,
    s.EmploymentType
ORDER BY
    CompletedLoans DESC,
    s.Department,
    s.EmploymentType;

-- ============================================================================
-- Query 8 | Severity bands for late returns
-- ============================================================================
WITH return_bands AS (
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
band_summary AS (
    SELECT
        ReturnTimingBand,
        COUNT(*) AS LoanCount,
        ROUND(AVG(LoanDurationDays), 2) AS AvgLoanDurationDays
    FROM return_bands
    GROUP BY
        ReturnTimingBand
)
SELECT
    ReturnTimingBand,
    LoanCount,
    ROUND(100.0 * LoanCount / SUM(LoanCount) OVER (), 2) AS SharePct,
    AvgLoanDurationDays
FROM band_summary
ORDER BY
    CASE ReturnTimingBand
        WHEN 'On time or early' THEN 1
        WHEN '1-3 days late' THEN 2
        WHEN '4-7 days late' THEN 3
        ELSE 4
    END;
