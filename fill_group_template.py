# Fills CA2_group_template.docx with task a)-d) answers
import copy
from docx import Document
from docx.shared import Inches, Pt
from docx.text.paragraph import Paragraph

d = Document('CA2_group_template.docx')

t0 = d.tables[0]
members = [("p2510877", "Kendrick Slamat (Leader)", "33.3"),
           ("p2510819", "Ang Wei Chong", "33.3"),
           ("p2510864", "Chin Guan Chung", "33.4")]
for i, (sid, name, pct) in enumerate(members, start=1):
    cells = t0.rows[i].cells
    cells[0].text, cells[1].text, cells[2].text = sid, name, pct

issues = [
 ("data.xlsx / Members", "M0197", "Invalid TierID 'T00001' (extra zero; no such tier exists)", "Corrected to 'T0001'"),
 ("data.xlsx / Members", "All 301 rows", "Gender stored as 'Male'/'Female' but schema requires CHAR(1)", "Mapped to 'M'/'F'"),
 ("data.xlsx / Members", "M0301", "DateOfBirth stored as datetime '1990-05-08 00:00:00' instead of a date", "Truncated to '1990-05-08'"),
 ("data.xlsx / Members", "All rows", "Two contact fields (ContactNo, Email) but Member table has a single Contact column", "Used Email as Contact, consistent with how staff contacts are stored"),
 ("data.xlsx / Members", "43 rows", "Missing Occupation", "Kept as NULL (column is nullable; value genuinely unknown)"),
 ("staff.csv", "All 51 rows", "Gender stored as 'Male'/'Female' but schema requires CHAR(1)", "Mapped to 'M'/'F'"),
 ("staff.csv", "1 row", "StartDatetime in inconsistent format '2/18/2011 13:55' (rest are ISO); schema needs DATE", "Parsed both formats and truncated to date"),
 ("staff.csv", "S0003", "'Julia Mahmud' has Gender = Male, which cannot be verified against any source", "Left unchanged; flagged for tutor"),
 ("data.xlsx / BookCopies", "4 rows", "Status misspelled as 'Availble'", "Corrected to 'Available'"),
 ("data.xlsx / BookCopies", "B00489 copy 2", "Status 'Available' although the copy has an open (unreturned) loan", "Status set to 'On Loan', per circulation rules in the case description"),
 ("data.xlsx / Loans", "M0107/B00153", "Row references StaffID 'S0101' (staff run S0001-S0051) and CopySeqNo 8 (book has 3 copies); DueDate 2023-04-02 precedes LoanDatetime 2024-07-04", "Row removed: it violates two foreign keys and cannot be repaired without fabricating data. To confirm with tutor."),
 ("data.xlsx / Loans", "7 rows", "Missing LoanStatus (6 returned, 1 outstanding)", "No correction needed for insertion: LoanStatus is not a column in the Loan table; status is derivable from ReturnDatetime"),
]
t1 = d.tables[1]
while len(t1.rows) < len(issues) + 1:
    t1.add_row()
for i, row in enumerate(issues, start=1):
    for j, v in enumerate(row):
        t1.rows[i].cells[j].text = v
        for p in t1.rows[i].cells[j].paragraphs:
            for r in p.runs:
                r.font.size = Pt(9)


def insert_after(par, text=None, image=None, width=None, bold=False, size=10):
    new = copy.deepcopy(par._p)
    for child in list(new):
        new.remove(child)
    par._p.addnext(new)
    np = Paragraph(new, par._parent)
    np.style = d.styles['Normal']
    if image:
        run = np.add_run()
        run.add_picture(image, width=width)
    elif text is not None:
        run = np.add_run(text)
        run.bold = bold
        run.font.size = Pt(size)
    return np


def find(sub):
    return next(p for p in d.paragraphs if sub in p.text)


p = find('Paste your database diagram of your OLTP tables')
insert_after(p, '<< PASTE MySQL Workbench reverse-engineered diagram of CA22B2105 here >>', bold=True)

p = find('Design your DW using star or snowflake schema')
expl = ("Design explanation: We adopted a STAR SCHEMA with one fact table, FactLoan, whose grain is one completed "
        "loan transaction (a book borrowed and returned), matching the brief's primary analytical focus on loan "
        "duration and borrowing activity. Four dimensions surround it: DimMember, DimStaff, DimBook and DimDate. "
        "Every table, including the fact and time dimension, uses an AUTO_INCREMENT surrogate key. "
        "Membership-tier attributes (TierName, TierLevel, BorrowLimit) are denormalised into DimMember, and the "
        "minimum-tier requirement into DimBook, so no snowflaked outrigger tables are needed - this keeps queries "
        "to single joins and suits the read-oriented workload. DimDate is kept at DAY granularity as instructed "
        "(date, day of week, weekend flag, month, quarter, year) and is role-played twice by the fact table, as "
        "borrow date and return date. CopySeqNo is carried as a degenerate dimension for traceability to the "
        "physical copy. Pre-computed measures: LoanDurationDays (return - borrow), DaysBeforeDue (due - return; "
        "negative means late) and an IsLate flag, so common analyses need no date arithmetic at query time. "
        "Assumptions: only completed loans are loaded (the single open loan is excluded from the fact table); "
        "slowly changing dimensions are out of scope per the brief - if tier changes had to be tracked, DimMember "
        "could be extended to SCD Type 2 with effective-date columns.")
insert_after(p, expl)
insert_after(p, image='dw_erd.png', width=Inches(6.5))

p = find('Paste your database diagram for your DW in the box below')
ver = ("ETL verification: (1) Row-count reconciliation - completed loans in OLTP (SELECT COUNT(*) FROM Loan WHERE "
       "ReturnDatetime IS NOT NULL) = 12,343 and FactLoan = 12,343; DimMember = Member = 301; DimBook = Book = 500; "
       "DimStaff = Staff = 51. (2) Measure reconciliation - SUM(DATEDIFF(ReturnDatetime, StartDatetime)) computed "
       "directly on the OLTP Loan table = 108,801 days, identical to SUM(LoanDurationDays) in FactLoan, proving the "
       "duration measure was derived correctly for every row. (3) Referential integrity - a LEFT JOIN from FactLoan "
       "to each dimension returns 0 orphan rows, and all foreign keys are enforced by constraints so no fact row can "
       "reference a missing dimension member. The verification queries are included at the bottom of DW_insert.sql.")
insert_after(p, ver)
insert_after(p, '<< PASTE MySQL Workbench reverse-engineered diagram of CA2DW2B2104 here >>', bold=True)

analyses = [
 ("Objective: identify long-term and seasonal trends in loan volume by month and year (time dimension). "
  "Results: monthly completed loans grew from ~35/month in 2020 to 2,838 in December 2025, with a clear year-end "
  "surge every year (Dec 2022: 90 vs Nov 57; Dec 2024: 235 vs Nov 177; Dec 2025: 2,838 vs Nov 1,188). Average loan "
  "duration stays stable at 8-9.5 days throughout. "
  "Insight: borrowing activity is growing rapidly (roughly doubling year on year since 2023) and peaks sharply in "
  "November-December. Staffing and stock planning should anticipate the December peak; the stable duration shows "
  "the 14-day policy comfortably covers actual reading time."),
 ("Objective: find the borrowing pattern across days of the week to support staffing decisions (time dimension). "
  "Results: Sunday (35.9%) and Saturday (33.9%) together account for 69.8% of all loans; each weekday contributes "
  "only 5-7% (Friday lowest at 5.3%). "
  "Insight: demand is overwhelmingly a weekend phenomenon. Counter staffing and shelving operations should be "
  "concentrated on weekends, while system maintenance and stock-taking are best scheduled on Fridays."),
 ("Objective: compare genre popularity in absolute loans and loans per title, plus reading pace (book dimension). "
  "Results: Research Journal has the most total loans (2,093) but only 21.8 loans per title, while Young Adult has "
  "the highest intensity (31.2 loans per title from just 39 titles); Children is high on both (1,873 loans, 28.0 per "
  "title). Average duration is similar across genres (8.4-9.3 days). "
  "Insight: Research Journal's volume comes from its large catalogue (96 titles), whereas Young Adult and Children "
  "titles are individually in much higher demand - these genres are the best candidates for additional copies."),
 ("Objective: detect outstanding members with significantly higher/lower activity (member dimension; loan count and "
  "total duration measures). Results: the top borrower, Evan Seah (Premium), completed 454 loans; Isaac Wilson "
  "(Premium) holds books longest in aggregate (5,726 days over 409 loans). Two of the top five are only Basic tier "
  "(Jasper Johnson 331, Theodore Campbell 324 loans). The least active members completed only 9-11 loans. "
  "Insight: activity varies by a factor of ~50 between the most and least active members. The heavy Basic-tier "
  "borrowers are prime candidates for tier upgrades, and the low-activity group could be targeted with re-engagement "
  "campaigns."),
 ("Objective: examine whether membership tier relates to return discipline (member dimension x lateness measures). "
  "Results: late-return rate falls as tier rises - Basic 8.94%, Advanced 8.12%, Premium 7.94% - while average loan "
  "duration rises with tier (8.54 to 9.39 days). "
  "Insight: higher-tier members keep books slightly longer but return them more punctually, so the higher borrow "
  "limits given to upper tiers are not causing overdue problems. Late-return interventions (reminders, penalties) "
  "would be most effective aimed at Basic members."),
 ("Objective: multi-dimensional analysis (genre x month) - do Children and Young Adult loans spike in school-holiday "
  "months? Results: Children loans climb from 65 in January to 486 in December (7.5x), with secondary highs in "
  "June-July (126/131); Young Adult mirrors this (51 in January to 301 in December). "
  "Insight: youth borrowing is strongly seasonal and concentrated in the November-December school holidays, "
  "compounding the overall year-end surge from Analysis 1. The library should time children's programmes, new "
  "acquisitions and extra copies of popular youth titles for Q4."),
]
for i, text in enumerate(analyses, start=1):
    anchor = next(p for p in d.paragraphs if p.text.strip() == '%d.' % i)
    insert_after(anchor, text)

for lbl in ('7.', '8.'):
    p = next(p for p in d.paragraphs if p.text.strip() == lbl)
    p._p.getparent().remove(p._p)

d.save('2B21-05_group_submission.docx')
print('saved')
