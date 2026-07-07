| Table | Issue identified | Correction applied | Rows |
|---|---|---|---|
| Member | Invalid TierID 'T00001' (extra zero, no such tier) | Corrected to 'T0001' | 1 |
| Member | Gender stored as 'Male'/'Female' but schema requires CHAR(1) | Mapped to 'M'/'F' | 301 |
| Member | One DateOfBirth stored as datetime ('1990-05-08 00:00:00') instead of date | Truncated to date '1990-05-08' | 1 |
| Member | Two contact fields (ContactNo, Email) but schema has a single Contact column | Used Email as Contact (consistent with staff records) | 301 |
| Member | Missing Occupation values | Kept as NULL (column is nullable; occupation genuinely unknown) | 43 |
| Staff | Gender stored as 'Male'/'Female' but schema requires CHAR(1) | Mapped to 'M'/'F' | 51 |
| Staff | Inconsistent StartDatetime format (one row 'M/D/YYYY H:MM', rest ISO) and schema wants DATE not DATETIME | Parsed both formats, truncated to date | 1 |
| Staff | S0003 'Julia Mahmud' has Gender = Male; cannot be verified against any source | Left as-is, flagged for tutor | 1 |
| BookCopy | Misspelled status 'Availble' | Corrected to 'Available' | 4 |
| Loan | Row M0107/B00153: StaffID 'S0101' does not exist (staff run S0001-S0051), CopySeqNo 8 does not exist (book has 3 copies), DueDate 2023-04-02 precedes LoanDatetime 2024-07-04 | Row removed - unrecoverable without fabricating data; violates FK constraints. Flagged for tutor confirmation | 1 |
| Loan | Missing LoanStatus on 7 rows (6 returned, 1 outstanding) | Column not in OLTP schema; status derivable from ReturnDatetime, no insert impact | 7 |
| BookCopy | Copy B00489 #2 marked 'Available' despite an open (unreturned) loan | Status set to 'On Loan' per system rules in the brief | 1 |
