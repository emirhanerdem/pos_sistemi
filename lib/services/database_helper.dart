import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/login_attempt.dart';
import '../models/payment_link.dart';
import '../models/payment_request.dart';
import '../models/transaction.dart';
import '../models/user.dart';

/// Local persistence for the app. There is no backend yet — everything
/// (members, transactions) is stored on-device in a SQLite database via
/// `sqflite`. Passwords are hashed (see `PasswordHasher`) before they ever
/// reach this layer, so the database itself never holds plaintext secrets.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'zanha_pay.db';
  static const _dbVersion = 3;

  /// Cut the POS provider takes from a transaction. The daily/weekly/monthly
  /// "hakediş" figure on the wallet screen is turnover minus this.
  static const commissionRate = 0.0179;

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  /// Closes and forgets the cached connection so the next call to
  /// [database] reopens it. Used to isolate tests from each other.
  @visibleForTesting
  Future<void> closeForTest() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        business_type TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pos_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payment_number TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        date INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        channel TEXT NOT NULL,
        installment_count INTEGER NOT NULL,
        payment_type TEXT NOT NULL,
        currency TEXT NOT NULL,
        card_number_masked TEXT NOT NULL,
        card_brand TEXT NOT NULL,
        source TEXT NOT NULL
      )
    ''');

    await _createSettingsAndAttemptsTables(db);
    await _createPaymentTables(db);

    for (final seed in _seedTransactions) {
      await db.insert('pos_transactions', seed.toMap()..remove('id'));
    }
    await _seedPaymentRequests(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsAndAttemptsTables(db);
    }
    if (oldVersion < 3) {
      await _createPaymentTables(db);
      await _seedPaymentRequests(db);
    }
  }

  Future<void> _createSettingsAndAttemptsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS login_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        success INTEGER NOT NULL,
        date INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createPaymentTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        note TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        date INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        token TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // --- Users -------------------------------------------------------------

  Future<int> insertUser(AppUser user) async {
    final db = await database;
    return db.insert('users', user.toMap()..remove('id'));
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<void> updatePasswordHash(String email, String newHash) async {
    final db = await database;
    await db.update(
      'users',
      {'password_hash': newHash},
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  Future<void> deleteUserByEmail(String email) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  // --- Settings (key/value) ------------------------------------------------

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }

  // --- Login attempts --------------------------------------------------------

  Future<void> insertLoginAttempt(String email, bool success) async {
    final db = await database;
    await db.insert('login_attempts', {
      'email': email.trim().toLowerCase(),
      'success': success ? 1 : 0,
      'date': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<LoginAttempt>> getLoginAttempts({int limit = 50}) async {
    final db = await database;
    final rows = await db.query(
      'login_attempts',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(LoginAttempt.fromMap).toList();
  }

  // --- Transactions --------------------------------------------------------

  Future<int> insertTransaction(PosTransaction transaction) async {
    final db = await database;
    return db.insert('pos_transactions', transaction.toMap()..remove('id'));
  }

  Future<List<PosTransaction>> getTransactions({
    PosChannel? channel,
    TransactionStatus? status,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (channel != null) {
      conditions.add('channel = ?');
      args.add(channel.name);
    }
    if (status != null) {
      conditions.add('status = ?');
      args.add(status.name);
    }
    final rows = await db.query(
      'pos_transactions',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return rows.map(PosTransaction.fromMap).toList();
  }

  Future<void> updateTransactionStatus(
    int id,
    TransactionStatus status,
    String type,
  ) async {
    final db = await database;
    await db.update(
      'pos_transactions',
      {'status': status.name, 'type': type},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Sum of successful collections in `[from, to)`. Drives the turnover card
  /// on the wallet screen.
  Future<double> getTurnover({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM pos_transactions '
      'WHERE status = ? AND date >= ? AND date < ?',
      [
        TransactionStatus.success.name,
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
    );
    return (rows.first['total'] as num).toDouble();
  }

  // --- Payment requests ----------------------------------------------------

  Future<int> insertPaymentRequest(PaymentRequest request) async {
    final db = await database;
    return db.insert('payment_requests', request.toMap()..remove('id'));
  }

  Future<List<PaymentRequest>> getPaymentRequests({
    PaymentRequestStatus? status,
  }) async {
    final db = await database;
    final rows = await db.query(
      'payment_requests',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status.name],
      orderBy: 'date DESC',
    );
    return rows.map(PaymentRequest.fromMap).toList();
  }

  Future<int> getPendingPaymentRequestCount() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM payment_requests WHERE status = ?',
      [PaymentRequestStatus.pending.name],
    );
    return (rows.first['total'] as num).toInt();
  }

  Future<void> updatePaymentRequestStatus(
    int id,
    PaymentRequestStatus status,
  ) async {
    final db = await database;
    await db.update(
      'payment_requests',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePaymentRequest(int id) async {
    final db = await database;
    await db.delete('payment_requests', where: 'id = ?', whereArgs: [id]);
  }

  // --- Payment links -------------------------------------------------------

  Future<int> insertPaymentLink(PaymentLink link) async {
    final db = await database;
    return db.insert('payment_links', link.toMap()..remove('id'));
  }

  Future<List<PaymentLink>> getPaymentLinks() async {
    final db = await database;
    final rows = await db.query('payment_links', orderBy: 'created_at DESC');
    return rows.map(PaymentLink.fromMap).toList();
  }

  Future<void> updatePaymentLinkStatus(int id, PaymentLinkStatus status) async {
    final db = await database;
    await db.update(
      'payment_links',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePaymentLink(int id) async {
    final db = await database;
    await db.delete('payment_links', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _seedPaymentRequests(Database db) async {
    final now = DateTime.now();
    final seeds = [
      ('Yaşar Aşık', '0532 111 22 33', 'Masa 4 hesabı', 1250.00, 35),
      ('Asım Aşık', '0533 222 33 44', 'Online sipariş #1042', 480.75, 140),
      ('Alp Aşık', '0534 333 44 55', 'Servis bedeli', 2300.50, 320),
      ('Aysima Aşık', '0535 444 55 66', 'Kapora', 750.00, 1400),
      ('Deniz Yıldız', '0536 555 66 77', 'Abonelik yenileme', 199.90, 2880),
    ];
    for (final (name, phone, note, amount, minutesAgo) in seeds) {
      await db.insert(
        'payment_requests',
        PaymentRequest(
          customerName: name,
          phone: phone,
          note: note,
          amount: amount,
          date: now.subtract(Duration(minutes: minutesAgo)),
        ).toMap()..remove('id'),
      );
    }
  }

  static final List<PosTransaction> _seedTransactions = [
    PosTransaction(
      paymentNumber: 'adfa646as7',
      customerName: 'Yaşar Aşık',
      date: DateTime(2010, 10, 10, 15, 20),
      type: 'İade',
      amount: 100000.25,
      status: TransactionStatus.refunded,
      channel: PosChannel.soft,
    ),
    PosTransaction(
      paymentNumber: 'bxa213qw9',
      customerName: 'Asım Aşık',
      date: DateTime(2010, 10, 10, 15, 20),
      type: 'İptal',
      amount: 100000.25,
      status: TransactionStatus.pending,
      channel: PosChannel.soft,
    ),
    PosTransaction(
      paymentNumber: 'clm998zz1',
      customerName: 'Alp Aşık',
      date: DateTime(2010, 10, 10, 15, 20),
      type: 'Başarılı',
      amount: 100000.25,
      status: TransactionStatus.success,
      channel: PosChannel.soft,
      installmentCount: 5,
      paymentType: 'Taksit',
    ),
    PosTransaction(
      paymentNumber: 'dpo554nb2',
      customerName: 'Aysima Aşık',
      date: DateTime(2010, 10, 10, 15, 20),
      type: 'İptal',
      amount: 100000.25,
      status: TransactionStatus.failed,
      channel: PosChannel.soft,
    ),
    PosTransaction(
      paymentNumber: 'ftr091ka5',
      customerName: 'Merve Kaya',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      type: 'Başarılı',
      amount: 10000.50,
      status: TransactionStatus.success,
      channel: PosChannel.soft,
    ),
    PosTransaction(
      paymentNumber: 'gkl772mn8',
      customerName: 'Emre Doğan',
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: 'Başarılı',
      amount: 4250.00,
      status: TransactionStatus.success,
      channel: PosChannel.sanal,
    ),
    PosTransaction(
      paymentNumber: 'hyz338pq4',
      customerName: 'Selin Arslan',
      date: DateTime.now().subtract(const Duration(days: 12)),
      type: 'Başarılı',
      amount: 7890.25,
      status: TransactionStatus.success,
      channel: PosChannel.sanal,
    ),
  ];
}
