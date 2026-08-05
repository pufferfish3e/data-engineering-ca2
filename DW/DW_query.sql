-- ST1501 CA2 Task d) - Data warehouse analytics (8 queries, group of 4)
-- MySQL 8.0+ is required for the window function in Query 8.
USE CA2DW2B2104;

-- ============================================================================
-- Query 1 | Monthly loan volume and average duration
-- ============================================================================
-- Join each completed loan to its borrow date, then aggregate the fact rows by
-- calendar month. Month number is included to keep January-December order.
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
-- Query 2 | Staff workload by department and employment type
-- ============================================================================
-- Count completed loans processed by each department/employment-type group.
-- AVG(IsLate) converts the 0/1 late flag into the group's late-return percentage.
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
-- Query 3 | Borrowing pattern by day of week
-- ============================================================================
-- Count completed loans by weekday. The scalar subquery supplies the overall
-- fact-row count so each weekday can also be expressed as a percentage of all loans.
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
-- Query 4 | Monthly demand for Children and Young Adult genres
-- ============================================================================
-- Restrict the fact rows to the two requested genres, then group by month.
-- Month number is retained only for chronological sorting in the final result.
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
-- Query 5 | Members with the highest and lowest borrowing activity
-- ============================================================================
-- First summarise each member once in a CTE. The two ordered result sets then
-- return the five most-active and five least-active members without re-joining.
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
-- Sort descending to select the five members with the greatest loan count.
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
-- Sort ascending to select the five members with the smallest loan count.
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
-- Query 6 | Average completed loans and return discipline by membership tier
-- ============================================================================
-- IsLate is stored as 1 for a late return and 0 otherwise, so SUM(IsLate)
-- counts late returns and its percentage gives the late-return rate per tier.
-- Dividing the tier's completed loans by its distinct active members produces
-- the average number of completed loans per borrowing member.
SELECT
    m.TierName,
    COUNT(*) AS TotalLoans,
    COUNT(DISTINCT m.MemberKey) AS ActiveMembers,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT m.MemberKey), 2) AS AvgCompletedLoans,
    SUM(f.IsLate) AS LateReturns,
    ROUND(SUM(f.IsLate) * 100.0 / COUNT(*), 2) AS LatePct,
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
-- Query 7 | Genre popularity and borrowing intensity per title
-- ============================================================================
-- Measure both total demand and catalogue breadth per genre. LoansPerBook
-- prevents a genre with many titles appearing popular only because it is larger.
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
-- Query 8 | Severity bands for late returns
-- ============================================================================
-- The first CTE classifies every completed loan from DaysBeforeDue: a negative
-- value means it was returned after its due date. The second CTE summarises bands.
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
-- Count the loans and calculate average duration within each return-timing band.
band_summary AS (
    SELECT
        ReturnTimingBand,
        COUNT(*) AS LoanCount,
        ROUND(AVG(LoanDurationDays), 2) AS AvgLoanDurationDays
    FROM return_bands
    GROUP BY
        ReturnTimingBand
)
-- The window total calculates each band's share without collapsing the four rows.
-- CASE assigns business-friendly order: on time first, then increasingly late.
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
