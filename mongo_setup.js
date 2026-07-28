// Task e)(i): build CA2Mongo.Book from the OLTP extract CSV.
// Run from this project folder: mongosh --file .\mongo_setup.js

const fs = require('fs');
const csvFilePath = 'oltp data deng.csv';

function parseCsv(text) {
    const rows = [];
    let row = [];
    let value = '';
    let inQuotes = false;

    for (let i = 0; i < text.length; i += 1) {
        const character = text[i];

        if (inQuotes) {
            if (character === '"') {
                if (text[i + 1] === '"') {
                    value += '"';
                    i += 1;
                } else {
                    inQuotes = false;
                }
            } else {
                value += character;
            }
        } else if (character === '"') {
            inQuotes = true;
        } else if (character === ',') {
            row.push(value);
            value = '';
        } else if (character === '\n' || character === '\r') {
            if (character === '\r' && text[i + 1] === '\n') {
                i += 1;
            }
            row.push(value);
            if (row.some(cell => cell !== '')) {
                rows.push(row);
            }
            row = [];
            value = '';
        } else {
            value += character;
        }
    }

    if (inQuotes) {
        throw new Error('CSV contains an unclosed quoted value.');
    }
    if (value !== '' || row.length > 0) {
        row.push(value);
        rows.push(row);
    }
    return rows;
}

function requiredInteger(value, fieldName, rowNumber) {
    const number = Number(value);
    if (!Number.isSafeInteger(number) || number < 0) {
        throw new Error(`Row ${rowNumber}: ${fieldName} must be a non-negative integer.`);
    }
    return number;
}

if (!fs.existsSync(csvFilePath)) {
    throw new Error(`Cannot find ${csvFilePath}. Run mongosh from the project folder.`);
}

const rows = parseCsv(fs.readFileSync(csvFilePath, 'utf8'));
if (rows.length < 2) {
    throw new Error('The CSV must contain a header and at least one data row.');
}

const requiredHeaders = [
    'bookId',
    'title',
    'author',
    'genre',
    'minimumMembershipTier',
    'totalCopies',
    'lostCopies',
    'totalLoanTransactions'
];
const headers = rows[0].map(header => header.replace(/^\uFEFF/, '').trim());
const missingHeaders = requiredHeaders.filter(header => !headers.includes(header));
if (missingHeaders.length > 0) {
    throw new Error(`CSV is missing required column(s): ${missingHeaders.join(', ')}.`);
}

const column = Object.fromEntries(headers.map((header, index) => [header, index]));
const seenBookIds = new Set();
const books = rows.slice(1).map((row, index) => {
    const rowNumber = index + 2;
    if (row.length !== headers.length) {
        throw new Error(`Row ${rowNumber}: expected ${headers.length} columns, found ${row.length}.`);
    }

    const bookId = row[column.bookId].trim();
    if (!bookId) {
        throw new Error(`Row ${rowNumber}: bookId is required.`);
    }
    if (seenBookIds.has(bookId)) {
        throw new Error(`Row ${rowNumber}: duplicate bookId ${bookId}.`);
    }
    seenBookIds.add(bookId);

    const totalCopies = requiredInteger(row[column.totalCopies].trim(), 'totalCopies', rowNumber);
    const lostCopies = requiredInteger(row[column.lostCopies].trim(), 'lostCopies', rowNumber);
    if (lostCopies > totalCopies) {
        throw new Error(`Row ${rowNumber}: lostCopies cannot exceed totalCopies.`);
    }

    return {
        bookId,
        title: row[column.title].trim(),
        author: row[column.author].trim(),
        genre: row[column.genre].trim(),
        minimumMembershipTier: row[column.minimumMembershipTier].trim(),
        totalCopies,
        lostCopies,
        totalLoanTransactions: requiredInteger(
            row[column.totalLoanTransactions].trim(),
            'totalLoanTransactions',
            rowNumber
        )
    };
});

const ca2Mongo = db.getSiblingDB('CA2Mongo');
ca2Mongo.Book.drop();
ca2Mongo.createCollection('Book');
ca2Mongo.Book.insertMany(books, { ordered: true });
ca2Mongo.Book.createIndex({ bookId: 1 }, { unique: true, name: 'uq_bookId' });

const documentCount = ca2Mongo.Book.countDocuments();
if (documentCount !== books.length) {
    throw new Error(`Import verification failed: expected ${books.length} documents, found ${documentCount}.`);
}

print(`CSV rows read: ${books.length}`);
print(`Book documents inserted: ${documentCount}`);
print(`Database: ${ca2Mongo.getName()}, collection: Book`);
printjson(ca2Mongo.Book.aggregate([
    {
        $group: {
            _id: null,
            totalCopies: { $sum: '$totalCopies' },
            lostCopies: { $sum: '$lostCopies' },
            totalLoanTransactions: { $sum: '$totalLoanTransactions' }
        }
    },
    { $project: { _id: 0 } }
]).next());
