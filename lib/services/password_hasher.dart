import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Salted SHA-256 hash so the local SQLite database never stores a
/// plaintext password, even though everything stays on-device.
class PasswordHasher {
  PasswordHasher._();

  static const _salt = 'zanha_pay_local_salt_v1';

  static String hash(String password) {
    final bytes = utf8.encode('$_salt:$password');
    return sha256.convert(bytes).toString();
  }

  static bool verify(String password, String hash) {
    return PasswordHasher.hash(password) == hash;
  }
}
