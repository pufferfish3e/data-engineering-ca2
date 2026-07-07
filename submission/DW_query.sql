-- ST1501 CA2 Task d) - Data warehouse analytics (6 queries, group of 3)
-- Aspects covered: time trends, book/genre popularity, member behaviour,
-- staff operations, loan duration & lateness measures
USE CA2DW2B2105;

-- Q1 [Time] Monthly loan volume across years: seasonal pattern of borrowing
SELECT d.Year, d.MonthName, COUNT(*) AS TotalLoans, ROUND(AVG(f.LoanDurationDays),2) AS AvgDurationDays
FROM FactLoan f JOIN DimDate d ON f.BorrowDateKey = d.DateKey
GROUP BY d.Year, d.Month, d.MonthName
ORDER BY d.Year, d.Month;

-- Q2 [Time] Borrowing by day of week: staffing/demand pattern
SELECT d.DayOfWeek, COUNT(*) AS TotalLoans,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM FactLoan), 2) AS PctOfAllLoans
FROM FactLoan f JOIN DimDate d ON f.BorrowDateKey = d.DateKey
GROUP BY d.DayOfWeek, d.IsWeekend
ORDER BY TotalLoans DESC;

-- Q3 [Book/Genre] Genre popularity and reading pace
SELECT b.Genre, COUNT(*) AS TotalLoans,
       COUNT(DISTINCT b.BookKey) AS DistinctBooks,
       ROUND(COUNT(*) / COUNT(DISTINCT b.BookKey), 1) AS LoansPerBook,
       ROUND(AVG(f.LoanDurationDays), 2) AS AvgDurationDays
FROM FactLoan f JOIN DimBook b ON f.BookKey = b.BookKey
GROUP BY b.Genre
ORDER BY TotalLoans DESC;

-- Q4 [Member] Outstanding members: significantly above/below average activity
WITH per_member AS (
    SELECT m.MemberID, m.Name, m.TierName, COUNT(*) AS TotalLoans,
           SUM(f.LoanDurationDays) AS TotalDurationDays
    FROM FactLoan f JOIN DimMember m ON f.MemberKey = m.MemberKey
    GROUP BY m.MemberKey, m.MemberID, m.Name, m.TierName
)
(SELECT 'Top 5' AS Grp, p.* FROM per_member p ORDER BY TotalLoans DESC LIMIT 5)
UNION ALL
(SELECT 'Bottom 5', p.* FROM per_member p ORDER BY TotalLoans ASC LIMIT 5);

-- Q5 [Measure: lateness] Late-return rate by membership tier
SELECT m.TierName, COUNT(*) AS TotalLoans,
       SUM(f.IsLate) AS LateReturns,
       ROUND(SUM(f.IsLate) * 100.0 / COUNT(*), 2) AS LatePct,
       ROUND(AVG(f.LoanDurationDays), 2) AS AvgDurationDays
FROM FactLoan f JOIN DimMember m ON f.MemberKey = m.MemberKey
GROUP BY m.TierName, m.TierLevel
ORDER BY m.TierLevel;

-- Q6 [Multi-dimension: genre x time] Seasonal genre demand - do Children/Young Adult
-- loans spike in school holiday months (Jun, Nov, Dec)?
SELECT b.Genre, d.Month, d.MonthName, COUNT(*) AS TotalLoans
FROM FactLoan f
JOIN DimBook b ON f.BookKey = b.BookKey
JOIN DimDate d ON f.BorrowDateKey = d.DateKey
WHERE b.Genre IN ('Children', 'Young Adult')
GROUP BY b.Genre, d.Month, d.MonthName
ORDER BY b.Genre, d.Month;
