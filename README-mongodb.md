# MongoDB Book import (Task e)

`mongo_setup.js` creates the `CA2Mongo` database and its `Book` collection from
`oltp data deng.csv`. The CSV is the 500-row result of the one-document-per-book
OLTP extraction in `OLTP_extract.sql`.

## Before running

1. Complete the OLTP setup first. The SQL that produces the required Book extract
   is already in `OLTP_extract.sql`; paste that SQL under Task e)(i) in the
   individual template.
2. Ensure the source CSV is named exactly `oltp data deng.csv` and remains in this
   project folder. It must have these columns:

   `bookId`, `title`, `author`, `genre`, `minimumMembershipTier`, `totalCopies`,
   `lostCopies`, and `totalLoanTransactions`.
3. Start the MongoDB service if it is not already running:

   ```powershell
   Get-Service MongoDB
   Start-Service MongoDB
   ```

   `Start-Service` may require an elevated PowerShell window.

## Create the database and collection

Open PowerShell in this project folder and run:

```powershell
mongosh --file .\mongo_setup.js
```

The script validates every CSV row, drops and recreates only `CA2Mongo.Book`,
inserts the documents, creates a unique index on `bookId`, and verifies the
insert count. With the supplied CSV, the expected count is **500**.

Verify the database independently:

```powershell
mongosh --quiet --eval "const ca2 = db.getSiblingDB('CA2Mongo'); printjson({ database: ca2.getName(), collections: ca2.getCollectionNames(), bookCount: ca2.Book.countDocuments() })"
```

Expected values are `database: "CA2Mongo"`, `collections: [ "Book" ]`, and
`bookCount: 500`.

## Run the required Task e(ii) queries

```powershell
mongosh --file .\mongo_queries.js
```

For the supplied extract, both required queries return `[]`: no book has more
than 400 loan transactions (the maximum is 91), and no genre meets both the
more-than-50-books and average-more-than-70-loans conditions. This is valid
output, not an import failure.

## Assignment evidence

For Task e(i), include the SQL in `OLTP_extract.sql` and record `500` as the
Book collection document count. For Task e(ii), paste the commands from
`mongo_queries.js` and the actual mongosh output into the individual template.

The import is intentionally written entirely in JavaScript for MongoDB Shell
(`mongosh`); it does not use MongoDB Compass or another import program.
