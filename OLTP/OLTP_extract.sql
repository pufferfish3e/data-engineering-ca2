-- Task e)(i): extract one document per book from the OLTP database

USE CA22B2104;

-- Start from Book so every book appears, even if it has no copies or loans.
-- The two derived tables pre-calculate copy and loan totals before they are joined.
SELECT
    b.BookID AS bookId,
    b.Title AS title,
    b.Author AS author,
    b.Genre AS genre,
    mt.TierName AS minimumMembershipTier,
    IFNULL(c.totalCopies, 0) AS totalCopies,
    IFNULL(c.lostCopies, 0) AS lostCopies,
    IFNULL(l.totalLoanTransactions, 0) AS totalLoanTransactions
FROM Book AS b
JOIN MembershipTier AS mt
  ON mt.TierID = b.MinTierID
LEFT JOIN (
    -- One row per book: total copies and copies currently marked Lost.
    SELECT
        BookID,
        COUNT(*) AS totalCopies,
        SUM(CASE WHEN Status = 'Lost' THEN 1 ELSE 0 END) AS lostCopies
    FROM BookCopy
    GROUP BY BookID
) AS c
  ON c.BookID = b.BookID
LEFT JOIN (
    -- One row per book: total borrowing transactions across all its copies.
    SELECT
        BookID,
        COUNT(*) AS totalLoanTransactions
    FROM Loan
    GROUP BY BookID
) AS l
  ON l.BookID = b.BookID
ORDER BY b.BookID;
