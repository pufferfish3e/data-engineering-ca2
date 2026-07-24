-- Task e)(i): extract one document per book from the OLTP database

USE CA22B2104;

SELECT
    b.BookID AS bookId,
    b.Title AS title,
    b.Author AS author,
    b.Genre AS genre,
    mt.TierName AS minimumMembershipTier,
    COALESCE(c.totalCopies, 0) AS totalCopies,
    COALESCE(c.lostCopies, 0) AS lostCopies,
    COALESCE(l.totalLoanTransactions, 0) AS totalLoanTransactions
FROM Book AS b
JOIN MembershipTier AS mt
  ON mt.TierID = b.MinTierID
LEFT JOIN (
    SELECT
        BookID,
        COUNT(*) AS totalCopies,
        SUM(CASE WHEN Status = 'Lost' THEN 1 ELSE 0 END) AS lostCopies
    FROM BookCopy
    GROUP BY BookID
) AS c
  ON c.BookID = b.BookID
LEFT JOIN (
    SELECT
        BookID,
        COUNT(*) AS totalLoanTransactions
    FROM Loan
    GROUP BY BookID
) AS l
  ON l.BookID = b.BookID
ORDER BY b.BookID;
