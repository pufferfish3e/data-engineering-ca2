-- Task e)(i): extract one document per book from the OLTP database
USE CA22B2105;
SELECT b.BookID, b.Title, b.Author, b.Genre,
       t.TierName AS MinTierRequired,
       COUNT(DISTINCT c.CopySeqNo) AS TotalCopies,
       COUNT(DISTINCT CASE WHEN c.Status = 'Lost' THEN c.CopySeqNo END) AS LostCopies,
       (SELECT COUNT(*) FROM Loan l WHERE l.BookID = b.BookID) AS TotalLoans
FROM Book b
JOIN MembershipTier t ON b.MinTierID = t.TierID
LEFT JOIN BookCopy c ON c.BookID = b.BookID
GROUP BY b.BookID, b.Title, b.Author, b.Genre, t.TierName;
