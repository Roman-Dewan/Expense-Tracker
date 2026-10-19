import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart' as p;
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/budget.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'expense_tracker_advanced.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        type INTEGER NOT NULL
      )
    ''');

    // 2. Accounts / Wallets table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0.0,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');

    // 3. Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        notes TEXT,
        receipt_image_path TEXT,
        is_recurring INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Indices for optimal query speeds
    await db.execute('CREATE INDEX idx_tx_date ON transactions(date);');
    await db.execute('CREATE INDEX idx_tx_category ON transactions(category_id);');
    await db.execute('CREATE INDEX idx_tx_type ON transactions(type);');

    // 4. Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        month_year TEXT NOT NULL,
        amount_limit REAL NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Populate Default Categories
    final batch = db.batch();
    for (final cat in Category.defaultCategories) {
      batch.insert('categories', cat.toMap());
    }

    // Populate Default Accounts
    for (final acc in Account.defaultAccounts) {
      batch.insert('accounts', acc.toMap());
    }
    await batch.commit(noResult: true);
  }

  // ================= Transactions CRUD ================= //

  Future<List<Transaction>> getAllTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    TransactionType? type,
    String? accountId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }
    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }
    if (accountId != null && accountId.isNotEmpty) {
      whereClauses.add('(account_id = ? OR to_account_id = ?)');
      whereArgs.add(accountId);
      whereArgs.add(accountId);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR notes LIKE ?)');
      final pattern = '%${searchQuery.trim()}%';
      whereArgs.add(pattern);
      whereArgs.add(pattern);
    }

    final whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      'transactions',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<Transaction?> getTransactionById(String id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> batchInsertTransactions(
    List<Transaction> transactions, {
    bool overwriteExisting = false,
  }) async {
    final db = await database;
    final batch = db.batch();
    for (final tx in transactions) {
      batch.insert(
        'transactions',
        tx.toMap(),
        conflictAlgorithm: overwriteExisting
            ? ConflictAlgorithm.replace
            : ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Identifies transactions in [candidates] that are duplicates of existing records
  /// based on (title + amount + date within same day + type)
  Future<List<Transaction>> findDuplicates(List<Transaction> candidates) async {
    final db = await database;
    final existing = await db.query('transactions', columns: ['id', 'title', 'amount', 'date', 'type']);
    final duplicates = <Transaction>[];

    for (final candidate in candidates) {
      final candDateStr = candidate.date.toIso8601String().substring(0, 10);
      final isDup = existing.any((row) {
        final rowDateStr = (row['date'] as String).substring(0, 10);
        final rowAmount = (row['amount'] as num).toDouble();
        final rowTitle = (row['title'] as String).trim().toLowerCase();
        final rowType = row['type'] as String;

        return rowTitle == candidate.title.trim().toLowerCase() &&
            (rowAmount - candidate.amount).abs() < 0.001 &&
            rowDateStr == candDateStr &&
            rowType.toLowerCase() == candidate.type.name.toLowerCase();
      });

      if (isDup) {
        duplicates.add(candidate);
      }
    }

    return duplicates;
  }

  // ================= Categories CRUD ================= //

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'rowid ASC');
    final categories = maps.map((map) => Category.fromMap(map)).toList();

    // Preserve the natural defined order of categories without alphabetical sorting
    final defaultIndexMap = {
      for (int i = 0; i < Category.defaultCategories.length; i++)
        Category.defaultCategories[i].id: i
    };

    categories.sort((a, b) {
      final indexA = defaultIndexMap[a.id] ?? 999;
      final indexB = defaultIndexMap[b.id] ?? 999;
      return indexA.compareTo(indexB);
    });

    return categories;
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ================= Accounts CRUD ================= //

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final maps = await db.query('accounts', orderBy: 'name ASC');
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<int> insertAccount(Account account) async {
    final db = await database;
    return await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ================= Budgets CRUD ================= //

  Future<List<Budget>> getBudgetsForMonth(String monthYear) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'month_year = ?',
      whereArgs: [monthYear],
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<int> setBudget(Budget budget) async {
    final db = await database;
    return await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budgets');
  }
}
