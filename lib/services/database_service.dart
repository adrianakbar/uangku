import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'widget_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
  static const String _apiBase = 'https://api.adrianakbar.my.id/api';

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

    // Migrasi otomatis jika tabel settings menggunakan kolom 'key'/'value' (reserved keywords)
    try {
      final columns = await db.rawQuery('PRAGMA table_info(settings)');
      bool hasOldColumns = false;
      for (var col in columns) {
        if (col['name'] == 'key' || col['name'] == 'value') {
          hasOldColumns = true;
          break;
        }
      }
      if (hasOldColumns) {
        await db.execute('DROP TABLE settings');
      }
    } catch (_) {}

    // Pastikan tabel settings selalu ada dengan nama kolom yang aman
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT
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

    // 4. Buat Tabel Settings dengan nama kolom yang aman
    await db.execute('''
      CREATE TABLE settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT
      )
    ''');
  }

  // --- METHODS UNTUK USER ---

  Future<int> insertUser(Map<String, dynamic> userRow) async {
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userRow),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return 1;
      }
    } catch (e) {
      debugPrint('Error insertUser: $e');
    }
    final db = await database;
    return await db.insert(
      'users',
      userRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update hanya kolom photo_url untuk user tertentu
  Future<int> updateUserPhoto(String email, String? photoUrl) async {
    try {
      final user = await getUserByEmail(email);
      if (user != null) {
        user['photo_url'] = photoUrl;
        await http.post(
          Uri.parse('$_apiBase/users'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(user),
        );
      }
    } catch (e) {
      debugPrint('Error updateUserPhoto: $e');
    }
    final db = await database;
    return await db.update(
      'users',
      {'photo_url': photoUrl},
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final res = await http.get(Uri.parse('$_apiBase/users/${Uri.encodeComponent(email)}'));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error getUserByEmail: $e');
    }
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
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transactionRow),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        changeNotifier.value++;
        WidgetService().updateWidget();
        return 1;
      }
    } catch (e) {
      debugPrint('Error insertTransaction: $e');
    }
    return 0;
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> transactionRow) async {
    try {
      final res = await http.put(
        Uri.parse('$_apiBase/transactions/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transactionRow),
      );
      if (res.statusCode == 200) {
        changeNotifier.value++;
        WidgetService().updateWidget();
        return 1;
      }
    } catch (e) {
      debugPrint('Error updateTransaction: $e');
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getTransactionsForUser(String email) async {
    return getTransactionsForUserFiltered(email);
  }

  // Ambil transaksi dengan filter rentang tanggal
  Future<List<Map<String, dynamic>>> getTransactionsForUserFiltered(
    String email, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$_apiBase/transactions?email=${Uri.encodeComponent(email)}';
      if (startDate != null) {
        url += '&startDate=${Uri.encodeComponent(startDate.toIso8601String())}';
      }
      if (endDate != null) {
        url += '&endDate=${Uri.encodeComponent(endDate.toIso8601String())}';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          map['amount'] = (map['amount'] as num).toDouble();
          return map;
        }).toList();
      }
    } catch (e) {
      debugPrint('Error getTransactionsForUserFiltered: $e');
    }
    return [];
  }

  // Hitung ringkasan (saldo, pemasukan, pengeluaran) dengan filter rentang tanggal
  Future<Map<String, double>> getSummaryForUserFiltered(
    String email, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$_apiBase/summary?email=${Uri.encodeComponent(email)}';
      if (startDate != null) {
        url += '&startDate=${Uri.encodeComponent(startDate.toIso8601String())}';
      }
      if (endDate != null) {
        url += '&endDate=${Uri.encodeComponent(endDate.toIso8601String())}';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        return {
          'balance': (data['balance'] as num).toDouble(),
          'income': (data['income'] as num).toDouble(),
          'expense': (data['expense'] as num).toDouble(),
        };
      }
    } catch (e) {
      debugPrint('Error getSummaryForUserFiltered: $e');
    }
    return {'balance': 0.0, 'income': 0.0, 'expense': 0.0};
  }

  Future<int> deleteTransaction(int id) async {
    try {
      final res = await http.delete(Uri.parse('$_apiBase/transactions/$id'));
      if (res.statusCode == 200) {
        changeNotifier.value++;
        WidgetService().updateWidget();
        return 1;
      }
    } catch (e) {
      debugPrint('Error deleteTransaction: $e');
    }
    return 0;
  }

  // Menghitung Saldo Bersih, Total Pemasukan, dan Total Pengeluaran
  Future<Map<String, double>> getSummaryForUser(String email) async {
    return getSummaryForUserFiltered(email);
  }

  // Melakukan Seed Data Awal untuk demo yang indah agar dasbor tidak kosong
  Future<void> seedDefaultDataForUser(String email) async {
    // Noop - Data is managed on the server
  }

  // --- METHODS UNTUK ANGGARAN (BUDGETS) ---

  Future<int> insertOrUpdateBudget(String category, double amount, String email) async {
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/budgets'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category': category,
          'amount': amount,
          'user_email': email,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        changeNotifier.value++;
        return 1;
      }
    } catch (e) {
      debugPrint('Error insertOrUpdateBudget: $e');
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getBudgetsForUser(String email) async {
    try {
      final res = await http.get(Uri.parse('$_apiBase/budgets?email=${Uri.encodeComponent(email)}'));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          map['amount'] = (map['amount'] as num).toDouble();
          return map;
        }).toList();
      }
    } catch (e) {
      debugPrint('Error getBudgetsForUser: $e');
    }
    return [];
  }

  Future<int> deleteBudget(String category, String email) async {
    try {
      final res = await http.delete(
        Uri.parse('$_apiBase/budgets?category=${Uri.encodeComponent(category)}&email=${Uri.encodeComponent(email)}')
      );
      if (res.statusCode == 200) {
        changeNotifier.value++;
        return 1;
      }
    } catch (e) {
      debugPrint('Error deleteBudget: $e');
    }
    return 0;
  }

  // Menghitung total pengeluaran per kategori untuk Analisis
  Future<Map<String, double>> getExpenseByCategory(String email) async {
    try {
      final res = await http.get(Uri.parse('$_apiBase/budgets/expense-by-category?email=${Uri.encodeComponent(email)}'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final Map<String, double> result = {};
        data.forEach((key, val) {
          result[key] = (val as num).toDouble();
        });
        return result;
      }
    } catch (e) {
      debugPrint('Error getExpenseByCategory: $e');
    }
    return {};
  }

  // --- METHODS UNTUK PENGATURAN & SESI ---

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'setting_key': key, 'setting_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'setting_key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['setting_value'] as String?;
    }
    return null;
  }

  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete(
      'settings',
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }

  Future<void> restoreDatabase(String backupPath) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'uangku.db');
    final backupFile = File(backupPath);
    await backupFile.copy(pathString);
    _database = await _initDatabase();
    changeNotifier.value++;
    WidgetService().updateWidget();
  }
}
