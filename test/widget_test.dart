import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:zanha_pay/main.dart';
import 'package:zanha_pay/services/database_helper.dart';

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

  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ZanhaPayApp());
    await tester.pumpAndSettle();

    expect(find.text('Üye Girişi'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Giriş Yap'), findsOneWidget);
  });
}
