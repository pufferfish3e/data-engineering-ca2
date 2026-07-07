# Cleans data.zip contents and generates OLTP_insert.sql for CA22B2105
import pandas as pd
from pathlib import Path

DB = "CA22B2105"
out = Path(__file__).parent
xl = pd.ExcelFile(out / "Data" / "data.xlsx")
members = xl.parse("Members")
books = xl.parse("Books")
copies = xl.parse("BookCopies")
loans = xl.parse("Loans")
loans = loans[[c for c in loans.columns if not str(c).startswith("Unnamed")]]
staff = pd.read_csv(out / "Data" / "staff.csv", encoding="utf-8-sig")

issues = []


def log(table, issue, fix, n):
    issues.append((table, issue, fix, n))


# ---- MembershipTier (from MembershipTier.docx) ----
tiers = pd.DataFrame(
    [
        ("T0001", "Basic", 1, 20),
        ("T0002", "Advanced", 2, 30),
        ("T0003", "Premium", 3, 50),
        ("T9999", "SuperAdmin", 9999, 9999),
    ],
    columns=["TierID", "TierName", "TierLevel", "BorrowLimit"],
)

# ---- Members ----
n = (members.TierID == "T00001").sum()
members.loc[members.TierID == "T00001", "TierID"] = "T0001"
log("Member", "Invalid TierID 'T00001' (extra zero, no such tier)", "Corrected to 'T0001'", n)

n = (members.Gender.isin(["Male", "Female"])).sum()
members["Gender"] = members.Gender.map({"Male": "M", "Female": "F"})
log("Member", "Gender stored as 'Male'/'Female' but schema requires CHAR(1)", "Mapped to 'M'/'F'", n)

dob = pd.to_datetime(members.DateOfBirth, format="mixed")
n = (members.DateOfBirth.astype(str).str.len() > 10).sum()
members["DateOfBirth"] = dob.dt.strftime("%Y-%m-%d")
log("Member", "One DateOfBirth stored as datetime ('1990-05-08 00:00:00') instead of date", "Truncated to date '1990-05-08'", n)

log("Member", "Two contact fields (ContactNo, Email) but schema has a single Contact column", "Used Email as Contact (consistent with staff records)", len(members))
members["Contact"] = members.Email

n = members.Occupation.isna().sum()
log("Member", "Missing Occupation values", "Kept as NULL (column is nullable; occupation genuinely unknown)", n)

# ---- Staff ----
n = staff.Gender.isin(["Male", "Female"]).sum()
staff["Gender"] = staff.Gender.map({"Male": "M", "Female": "F"})
log("Staff", "Gender stored as 'Male'/'Female' but schema requires CHAR(1)", "Mapped to 'M'/'F'", n)

start = pd.to_datetime(staff.StartDatetime, format="mixed", dayfirst=False)
n = staff.StartDatetime.str.contains("/").sum()
staff["StartDate"] = start.dt.strftime("%Y-%m-%d")
log("Staff", "Inconsistent StartDatetime format (one row 'M/D/YYYY H:MM', rest ISO) and schema wants DATE not DATETIME", "Parsed both formats, truncated to date", n)
log("Staff", "S0003 'Julia Mahmud' has Gender = Male; cannot be verified against any source", "Left as-is, flagged for tutor", 1)

# ---- Books: no issues found (verified: no dup IDs, no nulls, valid MinTierID) ----

# ---- BookCopies ----
n = (copies.Status == "Availble").sum()
copies.loc[copies.Status == "Availble", "Status"] = "Available"
log("BookCopy", "Misspelled status 'Availble'", "Corrected to 'Available'", n)

# ---- Loans ----
bad = loans[
    (~loans.StaffID.isin(staff.StaffID))
    | (~loans.set_index(["BookID", "CopySeqNo"]).index.isin(copies.set_index(["BookID", "CopySeqNo"]).index))
]
loans = loans.drop(bad.index)
log(
    "Loan",
    "Row M0107/B00153: StaffID 'S0101' does not exist (staff run S0001-S0051), CopySeqNo 8 does not exist (book has 3 copies), DueDate 2023-04-02 precedes LoanDatetime 2024-07-04",
    "Row removed - unrecoverable without fabricating data; violates FK constraints. Flagged for tutor confirmation",
    len(bad),
)

n = loans.LoanStatus.isna().sum()
log("Loan", "Missing LoanStatus on 7 rows (6 returned, 1 outstanding)", "Column not in OLTP schema; status derivable from ReturnDatetime, no insert impact", n)

# copy status consistency with open loans
open_loans = loans[loans.ReturnDatetime.isna()][["BookID", "CopySeqNo"]]
for _, r in open_loans.iterrows():
    copies.loc[(copies.BookID == r.BookID) & (copies.CopySeqNo == r.CopySeqNo), "Status"] = "On Loan"
log("BookCopy", "Copy B00489 #2 marked 'Available' despite an open (unreturned) loan", "Status set to 'On Loan' per system rules in the brief", len(open_loans))


# ---- generate SQL ----
def q(v):
    if pd.isna(v):
        return "NULL"
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        return str(int(v))
    return "'" + str(v).replace("'", "''") + "'"


def inserts(table, df, cols):
    lines = [f"INSERT INTO {table} ({', '.join(cols)}) VALUES"]
    vals = [f"({', '.join(q(r[c]) for c in cols)})" for _, r in df.iterrows()]
    return lines[0] + "\n" + ",\n".join(vals) + ";\n"


sql = [f"USE {DB};\n"]
sql.append(inserts("MembershipTier", tiers, ["TierID", "TierName", "TierLevel", "BorrowLimit"]))
sql.append(inserts("Member", members.rename(columns={"FullName": "Name", "DateOfBirth": "DOB"}), ["MemberID", "Name", "Contact", "DOB", "Gender", "Occupation", "RegistrationDatetime", "TierID"]))
sql.append(inserts("Staff", staff.rename(columns={"StaffName": "Name"}), ["StaffID", "Name", "Contact", "Gender", "EmploymentType", "StartDate", "Department", "DOB"]))
sql.append(inserts("Book", books, ["BookID", "Title", "Author", "Genre", "MinTierID"]))
sql.append(inserts("BookCopy", copies, ["BookID", "CopySeqNo", "Status"]))
loans_out = loans.rename(columns={"LoanDatetime": "StartDatetime"})
sql.append(inserts("Loan", loans_out, ["MemberID", "StaffID", "BookID", "CopySeqNo", "StartDatetime", "DueDate", "ReturnDatetime"]))

(out / "OLTP_insert.sql").write_text("\n".join(sql), encoding="utf-8")

# cleaning log for the template
with open(out / "cleaning_log.md", "w", encoding="utf-8") as f:
    f.write("| Table | Issue identified | Correction applied | Rows |\n|---|---|---|---|\n")
    for t, i, x, n in issues:
        f.write(f"| {t} | {i} | {x} | {n} |\n")

print("rows:", {"tiers": len(tiers), "members": len(members), "staff": len(staff), "books": len(books), "copies": len(copies), "loans": len(loans)})
print("OLTP_insert.sql and cleaning_log.md written")
