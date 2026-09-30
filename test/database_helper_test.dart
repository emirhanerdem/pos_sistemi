import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zanha_pay/models/payment_link.dart';
import 'package:zanha_pay/models/payment_request.dart';
import 'package:zanha_pay/models/transaction.dart';
import 'package:zanha_pay/models/user.dart';
import 'package:zanha_pay/services/database_helper.dart';
import 'package:zanha_pay/services/password_hasher.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper.instance.closeForTest();
    final path = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$path/zanha_pay.db');
  });

  test('seeds transactions for both POS channels on first run', () async {
    final transactions =
        await DatabaseHelper.instance.getTransactions(channel: PosChannel.soft);
    expect(transactions, hasLength(5));

    final sanal =
        await DatabaseHelper.instance.getTransactions(channel: PosChannel.sanal);
    expect(sanal, hasLength(2));
  });

  test('registers a user and authenticates with hashed password', () async {
    final hash = PasswordHasher.hash('Zanha2024%9!');
    await DatabaseHelper.instance.insertUser(
      AppUser(
        businessType: 'Şahıs Şirketi',
        firstName: 'Yasar',
        lastName: 'Asik',
        email: 'yasar.asik@example.com',
        phone: '5551234567',
        passwordHash: hash,
        createdAt: DateTime.now(),
      ),
    );

    final user =
        await DatabaseHelper.instance.getUserByEmail('yasar.asik@example.com');
    expect(user, isNotNull);
    expect(user!.firstName, 'Yasar');
    expect(PasswordHasher.verify('Zanha2024%9!', user.passwordHash), isTrue);
    expect(PasswordHasher.verify('wrong-password', user.passwordHash), isFalse);
  });

  test('inserting a transaction persists it and status updates apply',
      () async {
    final id = await DatabaseHelper.instance.insertTransaction(
      PosTransaction(
        paymentNumber: 'test123',
        customerName: 'Deniz Test',
        date: DateTime.now(),
        type: 'Başarılı',
        amount: 250.0,
        status: TransactionStatus.success,
        channel: PosChannel.soft,
      ),
    );

    var transactions =
        await DatabaseHelper.instance.getTransactions(channel: PosChannel.soft);
    expect(transactions, hasLength(6));
    expect(
      transactions.any((t) => t.paymentNumber == 'test123'),
      isTrue,
    );

    await DatabaseHelper.instance.updateTransactionStatus(
      id,
      TransactionStatus.refunded,
      'İade',
    );

    transactions =
        await DatabaseHelper.instance.getTransactions(channel: PosChannel.soft);
    final updated = transactions.firstWhere((t) => t.paymentNumber == 'test123');
    expect(updated.status, TransactionStatus.refunded);
    expect(updated.type, 'İade');
  });

  test('data survives closing and reopening the database', () async {
    await DatabaseHelper.instance.insertUser(
      AppUser(
        businessType: 'Limited Şirket',
        firstName: 'Persisted',
        lastName: 'User',
        email: 'persisted@example.com',
        phone: '5000000000',
        passwordHash: PasswordHasher.hash('SomeStrongPass1!'),
        createdAt: DateTime.now(),
      ),
    );

    // Simulate the app closing and the DatabaseHelper being reopened.
    await DatabaseHelper.instance.closeForTest();

    final user =
        await DatabaseHelper.instance.getUserByEmail('persisted@example.com');
    expect(user, isNotNull);
    expect(user!.lastName, 'User');
  });

  test('settings round-trip through SQLite (theme/accent/remember-me)',
      () async {
    expect(await DatabaseHelper.instance.getSetting('theme_option'), isNull);

    await DatabaseHelper.instance.setSetting('theme_option', 'dark');
    await DatabaseHelper.instance.setSetting('accent_color', '4294934071');
    expect(
      await DatabaseHelper.instance.getSetting('theme_option'),
      'dark',
    );

    // set again to confirm it replaces rather than duplicating the row.
    await DatabaseHelper.instance.setSetting('theme_option', 'navy');
    expect(
      await DatabaseHelper.instance.getSetting('theme_option'),
      'navy',
    );

    await DatabaseHelper.instance.deleteSetting('theme_option');
    expect(await DatabaseHelper.instance.getSetting('theme_option'), isNull);
  });

  test('login attempts are recorded and listed most-recent first', () async {
    await DatabaseHelper.instance.insertLoginAttempt('a@example.com', true);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await DatabaseHelper.instance.insertLoginAttempt('b@example.com', false);

    final attempts = await DatabaseHelper.instance.getLoginAttempts();
    expect(attempts, hasLength(2));
    expect(attempts.first.email, 'b@example.com');
    expect(attempts.first.success, isFalse);
    expect(attempts.last.email, 'a@example.com');
    expect(attempts.last.success, isTrue);
  });

  test('password can be updated and the account can be deleted', () async {
    await DatabaseHelper.instance.insertUser(
      AppUser(
        businessType: 'Şahıs Şirketi',
        firstName: 'Silinecek',
        lastName: 'Kullanici',
        email: 'silinecek@example.com',
        phone: '5559998877',
        passwordHash: PasswordHasher.hash('IlkSifre123!'),
        createdAt: DateTime.now(),
      ),
    );

    await DatabaseHelper.instance.updatePasswordHash(
      'silinecek@example.com',
      PasswordHasher.hash('YeniSifre456!'),
    );
    final updated =
        await DatabaseHelper.instance.getUserByEmail('silinecek@example.com');
    expect(
      PasswordHasher.verify('YeniSifre456!', updated!.passwordHash),
      isTrue,
    );

    await DatabaseHelper.instance.deleteUserByEmail('silinecek@example.com');
    expect(
      await DatabaseHelper.instance.getUserByEmail('silinecek@example.com'),
      isNull,
    );
  });

  test('filtering transactions by status narrows results', () async {
    final refunded = await DatabaseHelper.instance.getTransactions(
      channel: PosChannel.soft,
      status: TransactionStatus.refunded,
    );
    expect(refunded, hasLength(1));
    expect(refunded.first.status, TransactionStatus.refunded);
  });

  test('turnover only counts successful transactions inside the range',
      () async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final before = await DatabaseHelper.instance.getTurnover(
      from: startOfDay,
      to: endOfDay,
    );

    await DatabaseHelper.instance.insertTransaction(
      PosTransaction(
        paymentNumber: 'today-ok',
        customerName: 'Bugün Başarılı',
        date: now,
        type: 'Başarılı',
        amount: 100.0,
        status: TransactionStatus.success,
        channel: PosChannel.soft,
      ),
    );
    // Neither of these may be counted: one failed, one is outside the day.
    await DatabaseHelper.instance.insertTransaction(
      PosTransaction(
        paymentNumber: 'today-fail',
        customerName: 'Bugün Başarısız',
        date: now,
        type: 'İptal',
        amount: 500.0,
        status: TransactionStatus.failed,
        channel: PosChannel.soft,
      ),
    );
    await DatabaseHelper.instance.insertTransaction(
      PosTransaction(
        paymentNumber: 'yesterday-ok',
        customerName: 'Dün Başarılı',
        date: startOfDay.subtract(const Duration(hours: 2)),
        type: 'Başarılı',
        amount: 900.0,
        status: TransactionStatus.success,
        channel: PosChannel.soft,
      ),
    );

    final after = await DatabaseHelper.instance.getTurnover(
      from: startOfDay,
      to: endOfDay,
    );
    expect(after - before, closeTo(100.0, 0.001));
  });

  test('seeds five pending payment requests and resolves them', () async {
    expect(await DatabaseHelper.instance.getPendingPaymentRequestCount(), 5);

    final pending = await DatabaseHelper.instance.getPaymentRequests(
      status: PaymentRequestStatus.pending,
    );
    await DatabaseHelper.instance.updatePaymentRequestStatus(
      pending.first.id!,
      PaymentRequestStatus.approved,
    );

    expect(await DatabaseHelper.instance.getPendingPaymentRequestCount(), 4);
    final approved = await DatabaseHelper.instance.getPaymentRequests(
      status: PaymentRequestStatus.approved,
    );
    expect(approved, hasLength(1));
    expect(approved.first.id, pending.first.id);
  });

  test('payment links round-trip and expose their public URL', () async {
    final now = DateTime.now();
    await DatabaseHelper.instance.insertPaymentLink(
      PaymentLink(
        title: 'Danışmanlık',
        customerName: 'Deniz Test',
        amount: 1500.0,
        token: 'abc123def456',
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
      ),
    );

    final links = await DatabaseHelper.instance.getPaymentLinks();
    expect(links, hasLength(1));
    expect(links.first.url, 'https://pay.zanhapay.com/l/abc123def456');
    expect(links.first.status, PaymentLinkStatus.active);
    expect(links.first.isExpired, isFalse);

    await DatabaseHelper.instance.updatePaymentLinkStatus(
      links.first.id!,
      PaymentLinkStatus.paid,
    );
    final paid = await DatabaseHelper.instance.getPaymentLinks();
    expect(paid.first.status, PaymentLinkStatus.paid);
  });

  test('an active link past its expiry date reports itself as expired', () {
    final now = DateTime.now();
    final link = PaymentLink(
      title: 'Süresi geçmiş',
      amount: 100.0,
      token: 'expired00000',
      createdAt: now.subtract(const Duration(days: 10)),
      expiresAt: now.subtract(const Duration(days: 3)),
    );
    expect(link.status, PaymentLinkStatus.active);
    expect(link.isExpired, isTrue);
    expect(link.statusLabel, 'Süresi Doldu');
  });
}
