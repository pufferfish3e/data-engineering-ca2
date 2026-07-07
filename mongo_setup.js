// Task e)(i): create CA2Mongo database and Book collection (mongosh)
use('CA2Mongo');
db.Book.drop();
const books = JSON.parse(fs.readFileSync('books.json', 'utf8'));
db.Book.insertMany(books);
print('Book documents inserted: ' + db.Book.countDocuments());
