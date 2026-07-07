use('CA2Mongo');

// e)(ii) Q1: titles, genres, loan counts of books borrowed more than 400 times,
// descending by loan count
print('--- Q1 ---');
db.Book.find(
    { totalLoans: { $gt: 400 } },
    { _id: 0, title: 1, genre: 1, totalLoans: 1 }
).sort({ totalLoans: -1 }).forEach(d => printjson(d));

// e)(ii) Q2: per genre - number of books and average loans per book;
// only genres with > 50 books and average loans > 70; sort by average desc
print('--- Q2 ---');
db.Book.aggregate([
    { $group: { _id: "$genre",
                numBooks: { $sum: 1 },
                avgLoansPerBook: { $avg: "$totalLoans" } } },
    { $match: { numBooks: { $gt: 50 }, avgLoansPerBook: { $gt: 70 } } },
    { $sort: { avgLoansPerBook: -1 } }
]).forEach(d => printjson(d));
