# CA2 — how to run everything (demo/interview notes)

## Starting MySQL (your server has no Windows service)
The databases live in a custom data directory. Start the server first:

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe" --datadir="C:\Users\kandy\mysql-data" --console
```

Leave that window open. Login: user `root`, password `DAAA-1B-03`, port 3306.
Databases: `CA22B2105` (OLTP) and `CA2DW2B2105` (DW).

## Workbench reverse-engineer diagrams (2 screenshots still needed)
1. Start the server (above), open MySQL Workbench, connect to localhost:3306 as root.
2. Database → Reverse Engineer → select `CA22B2105` → next through → screenshot the diagram.
3. Repeat for `CA2DW2B2105`.
4. Paste them into `2B21-05_group_submission.docx` at the two bold
   `<< PASTE MySQL Workbench ... >>` placeholders (tasks a and c), delete the placeholder
   lines, re-zip as `2B21-05.zip` (or re-copy into `submission/` and re-zip).

## MongoDB (task e)
MongoDB service is installed and running. To reproduce:
```powershell
& "C:\Users\kandy\AppData\Local\Programs\mongosh\mongosh.exe" --file mongo_setup.js   # loads CA2Mongo.Book (500 docs)
& "C:\Users\kandy\AppData\Local\Programs\mongosh\mongosh.exe" --file mongo_queries.js # runs the 2 queries
```
Both queries return EMPTY results on this data (max loans per book = 91 < 400;
no genre has >50 books AND avg loans >70). The commands are correct — verify with
relaxed thresholds if asked. **Confirm with tutor that empty results are expected.**

## Things flagged for the tutor
1. Deleted loan row M0107/B00153 (invalid staff S0101, invalid copy #8, due date before loan date).
2. Staff S0003 "Julia Mahmud" gender=Male left as-is.
3. Empty MongoDB query results (thresholds vs data).
4. Get feedback on the DW star schema BEFORE submission (the brief requires consulting the tutor on the dimensional model).

## Before submitting
- Paste the 2 Workbench diagrams (above) and re-zip.
- Adjust Contribution % in the group table if not equal thirds; group leader row is Kendrick — reorder if someone else is leader.
- Submit the AI-use declaration via the Brightspace link (mandatory, penalty if missed).
- Group zip: `submission/2B21-05.zip` (leader submits). Individual zip: `submission/p2510877-KendrickSlamat.zip`.
- Deadline: Friday 7 August 2026, 3:59 pm.

## File map
- `clean_and_generate.py` — data cleaning pipeline (regenerates OLTP_insert.sql + cleaning_log.md)
- `OLTP_insert.sql`, `DW_create.sql`, `DW_insert.sql`, `DW_query.sql` — submission scripts
- `query_results.txt` — task d query outputs
- `mongo_extract.sql`, `books.json`, `mongo_setup.js`, `mongo_queries.js` — task e artifacts
- `taskf_results*.txt` — EXPLAIN ANALYZE outputs used in the task f report
- `dw_erd.png` — star schema ERD (already embedded in the group doc)
