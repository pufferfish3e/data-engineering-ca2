// Task e)(ii): run after mongo_setup.js has loaded CA2Mongo.Book.
// To run the file: mongosh --file .\mongo_queries.js

const ca2Mongo = db.getSiblingDB('CA2Mongo');

print('--- Q1: books borrowed more than 400 times ---');
printjson(ca2Mongo.Book.find(
    { totalLoanTransactions: { $gt: 400 } },
    { _id: 0, title: 1, genre: 1, totalLoanTransactions: 1 }
).sort({ totalLoanTransactions: -1, title: 1 }).toArray());

print('--- Q2: qualifying genre loan averages ---');
printjson(ca2Mongo.Book.aggregate([
    {
        $group: {
            _id: '$genre',
            numberOfBooks: { $sum: 1 },
            averageLoansPerBook: { $avg: '$totalLoanTransactions' }
        }
    },
    {
        $match: {
            numberOfBooks: { $gt: 50 },
            averageLoansPerBook: { $gt: 70 }
        }
    },
    {
        $project: {
            _id: 0,
            genre: '$_id',
            numberOfBooks: 1,
            averageLoansPerBook: { $round: ['$averageLoansPerBook', 2] }
        }
    },
    { $sort: { averageLoansPerBook: -1, genre: 1 } }
]).toArray());
