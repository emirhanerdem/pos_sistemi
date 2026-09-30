import 'dart:math';

const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _random = Random();

String _randomId(int length) =>
    List.generate(length, (_) => _chars[_random.nextInt(_chars.length)]).join();

/// Reference shown on receipts ("Ödeme Numarası").
String generatePaymentNumber() => _randomId(9);

/// Public part of a payment link URL.
String generateLinkToken() => _randomId(12);
