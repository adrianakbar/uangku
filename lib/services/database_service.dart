import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'uangku.db');

    final db = await openDatabase(
      pathString,
      version: 1,
      onCreate: _onCreate,
    );

    // Pastikan tabel budgets selalu ada untuk migrasi/pengguna lama
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        category TEXT,
        amount REAL NOT NULL,
        user_email TEXT,
        PRIMARY KEY (category, user_email)
      )
    ''');

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Buat Tabel Users
    await db.execute('''
      CREATE TABLE users (
        email TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        password TEXT,
        photo_url TEXT,
        auth_provider TEXT NOT NULL
      )
    ''');

    // 2. Buat Tabel Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        is_expense INTEGER NOT NULL,
        wallet TEXT NOT NULL,
        date TEXT NOT NULL,
        user_email TEXT NOT NULL,
        FOREIGN KEY (user_email) REFERENCES users (email) ON DELETE CASCADE
      )
    ''');

    // 3. Buat Tabel Budgets
    await db.execute('''
      CREATE TABLE budgets (
        category TEXT,
        amount REAL NOT NULL,
        user_email TEXT,
        PRIMARY KEY (category, user_email)
      )
    ''');
  }

  // --- METHODS UNTUK USER ---

  Future<int> insertUser(Map<String, dynamic> userRow) async {
    final db = await database;
    return await db.insert(
      'users',
      userRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // --- METHODS UNTUK TRANSAKSI ---

  Future<int> insertTransaction(Map<String, dynamic> transactionRow) async {
    final db = await database;
    final res = await db.insert(
      'transactions',
      transactionRow,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    changeNotifier.value++;
    return res;
  }

  Future<List<Map<String, dynamic>>> getTransactionsForUser(String email) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'LOWER(user_email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      orderBy: 'date DESC',
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    final res = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    changeNotifier.value++;
    return res;
  }

  // Menghitung Saldo Bersih, Total Pemasukan, dan Total Pengeluaran
  Future<Map<String, double>> getSummaryForUser(String email) async {
    final db = await database;
    final emailClean = email.trim().toLowerCase();

    // Hitung Total Pemasukan (is_expense = 0)
    final List<Map<String, dynamic>> incomeQuery = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE LOWER(user_email) = ? AND is_expense = 0',
      [emailClean],
    );
    final double totalIncome = (incomeQuery.first['total'] as num?)?.toDouble() ?? 0.0;

    // Hitung Total Pengeluaran (is_expense = 1)
    final List<Map<String, dynamic>> expenseQuery = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE LOWER(user_email) = ? AND is_expense = 1',
      [emailClean],
    );
    final double totalExpense = (expenseQuery.first['total'] as num?)?.toDouble() ?? 0.0;

    final double balance = totalIncome - totalExpense;

    return {
      'balance': balance,
      'income': totalIncome,
      'expense': totalExpense,
    };
  }

  // Melakukan Seed Data Awal untuk demo yang indah agar dasbor tidak kosong
  Future<void> seedDefaultDataForUser(String email) async {
    final db = await database;
    
    // Cek apakah user ini sudah memiliki transaksi
    final List<Map<String, dynamic>> existing = await db.query(
      'transactions',
      where: 'LOWER(user_email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (existing.isNotEmpty) return; // User sudah punya data, lewati seed

    final now = DateTime.now();
    final todayStr = now.toIso8601String();
    final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String();
    final twoDaysAgoStr = now.subtract(const Duration(days: 2)).toIso8601String();
    final fourDaysAgoStr = now.subtract(const Duration(days: 4)).toIso8601String();

    final List<Map<String, dynamic>> defaultTransactions = [
      {
        'title': 'Kopi Cappuccino Premium',
        'category': 'F&B',
        'amount': 35000.0,
        'is_expense': 1,
        'wallet': 'Cash',
        'date': todayStr,
        'user_email': email,
      },
      {
        'title': 'Gaji Pokok Bulanan',
        'category': 'Gaji',
        'amount': 12300000.0,
        'is_expense': 0,
        'wallet': 'BCA Savings',
        'date': yesterdayStr,
        'user_email': email,
      },
      {
        'title': 'Langganan Netflix Premium',
        'category': 'Hiburan',
        'amount': 186000.0,
        'is_expense': 1,
        'wallet': 'Gopay Wallet',
        'date': twoDaysAgoStr,
        'user_email': email,
      },
      {
        'title': 'Beli Bahan Makanan Mingguan',
        'category': 'Shopping',
        'amount': 3664000.0,
        'is_expense': 1,
        'wallet': 'Cash',
        'date': fourDaysAgoStr,
        'user_email': email,
      },
    ];

    final batch = db.batch();
    for (var tx in defaultTransactions) {
      batch.insert('transactions', tx);
    }
    await batch.commit(noResult: true);
  }

  // --- METHODS UNTUK ANGGARAN (BUDGETS) ---

  Future<int> insertOrUpdateBudget(String category, double amount, String email) async {
    final db = await database;
    final res = await db.insert(
      'budgets',
      {
        'category': category,
        'amount': amount,
        'user_email': email.trim().toLowerCase(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    changeNotifier.value++;
    return res;
  }

  Future<List<Map<String, dynamic>>> getBudgetsForUser(String email) async {
    final db = await database;
    return await db.query(
      'budgets',
      where: 'LOWER(user_email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  Future<int> deleteBudget(String category, String email) async {
    final db = await database;
    final res = await db.delete(
      'budgets',
      where: 'category = ? AND LOWER(user_email) = ?',
      whereArgs: [category, email.trim().toLowerCase()],
    );
    changeNotifier.value++;
    return res;
  }

  // Menghitung total pengeluaran per kategori untuk Analisis
  Future<Map<String, double>> getExpenseByCategory(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT category, SUM(amount) as total 
      FROM transactions 
      WHERE LOWER(user_email) = ? AND is_expense = 1
      GROUP BY category
    ''', [email.trim().toLowerCase()]);

    final Map<String, double> result = {};
    for (var row in maps) {
      final category = row['category'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      result[category] = total;
    }
    return result;
  }
}
