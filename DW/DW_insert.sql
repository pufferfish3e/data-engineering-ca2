-- ST1501 CA2 Task c) - ETL: load DW from OLTP (CA22B2105 -> CA2DW2B2104)
USE CA2DW2B2104;
SET SESSION cte_max_recursion_depth = 3000; -- 7 years of days exceeds the default 1000

-- DimDate: generate every calendar day covering the loan history (2020-01-01 to 2026-12-31)
INSERT INTO DimDate (FullDate, Day, DayOfWeek, IsWeekend, Month, MonthName, Quarter, Year)
WITH RECURSIVE dates AS (
    SELECT DATE('2020-01-01') AS d
    UNION ALL
    SELECT d + INTERVAL 1 DAY FROM dates WHERE d < '2026-12-31'
)
SELECT d, DAY(d), DAYNAME(d), DAYOFWEEK(d) IN (1,7), MONTH(d), MONTHNAME(d), QUARTER(d), YEAR(d)
FROM dates;

-- DimMember: denormalise membership tier into the member dimension
INSERT INTO DimMember (MemberID, Name, Gender, Occupation, RegistrationDate, TierName, TierLevel, BorrowLimit)
SELECT m.MemberID, m.Name, m.Gender, m.Occupation, DATE(m.RegistrationDatetime),
       t.TierName, t.TierLevel, t.BorrowLimit
FROM CA22B2104.Member m
JOIN CA22B2104.MembershipTier t ON m.TierID = t.TierID;

-- DimStaff
INSERT INTO DimStaff (StaffID, Name, Gender, EmploymentType, Department, StartDate)
SELECT StaffID, Name, Gender, EmploymentType, Department, StartDate
FROM CA22B2104.Staff;

-- DimBook: denormalise minimum tier into the book dimension
INSERT INTO DimBook (BookID, Title, Author, Genre, MinTierName, MinTierLevel)
SELECT b.BookID, b.Title, b.Author, b.Genre, t.TierName, t.TierLevel
FROM CA22B2104.Book b
JOIN CA22B2104.MembershipTier t ON b.MinTierID = t.TierID;

-- FactLoan: completed loans only (returned), per the analytical focus of the brief
INSERT INTO FactLoan (MemberKey, StaffKey, BookKey, BorrowDateKey,
                      CopySeqNo, LoanDurationDays, DaysBeforeDue, IsLate)
SELECT dm.MemberKey, ds.StaffKey, db.BookKey, bd.DateKey,
       l.CopySeqNo,
       DATEDIFF(DATE(l.ReturnDatetime), DATE(l.StartDatetime)),
       DATEDIFF(l.DueDate, DATE(l.ReturnDatetime)),
       DATE(l.ReturnDatetime) > l.DueDate
FROM CA22B2104.Loan l
JOIN DimMember dm ON dm.MemberID = l.MemberID
JOIN DimStaff  ds ON ds.StaffID  = l.StaffID
JOIN DimBook   db ON db.BookID   = l.BookID
JOIN DimDate   bd ON bd.FullDate = DATE(l.StartDatetime)
WHERE l.ReturnDatetime IS NOT NULL;

-- ===== ETL verification queries =====
-- 1) Row counts: fact rows must equal completed OLTP loans; dims must match source tables
SELECT (SELECT COUNT(*) FROM CA22B2104.Loan WHERE ReturnDatetime IS NOT NULL) AS oltp_completed_loans,
       (SELECT COUNT(*) FROM FactLoan) AS fact_rows,
       (SELECT COUNT(*) FROM CA22B2104.Member) AS oltp_members,
       (SELECT COUNT(*) FROM DimMember) AS dim_members,
       (SELECT COUNT(*) FROM CA22B2104.Book) AS oltp_books,
       (SELECT COUNT(*) FROM DimBook) AS dim_books,
       (SELECT COUNT(*) FROM CA22B2104.Staff) AS oltp_staff,
       (SELECT COUNT(*) FROM DimStaff) AS dim_staff;

-- 2) Measure sanity: total/average loan duration must match computed directly from OLTP
SELECT (SELECT SUM(DATEDIFF(DATE(ReturnDatetime), DATE(StartDatetime)))
          FROM CA22B2104.Loan WHERE ReturnDatetime IS NOT NULL) AS oltp_total_duration,
       (SELECT SUM(LoanDurationDays) FROM FactLoan) AS dw_total_duration;

-- 3) No orphan keys (all joins resolved during load)
SELECT COUNT(*) AS orphan_facts
FROM FactLoan f
LEFT JOIN DimMember dm ON f.MemberKey = dm.MemberKey
LEFT JOIN DimBook db ON f.BookKey = db.BookKey
WHERE dm.MemberKey IS NULL OR db.BookKey IS NULL;
