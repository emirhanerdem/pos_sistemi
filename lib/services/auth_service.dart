import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'database_helper.dart';
import 'password_hasher.dart';

enum LoginFailureReason { notFound, wrongPassword }

class LoginResult {
  final bool success;
  final AppUser? user;
  final LoginFailureReason? reason;

  const LoginResult.success(AppUser this.user)
      : success = true,
        reason = null;

  const LoginResult.failure(LoginFailureReason this.reason)
      : success = false,
        user = null;
}

/// Holds the signed-in member for the lifetime of the app and centralizes
/// every account operation (login, register, password change, deletion) so
/// screens don't talk to [DatabaseHelper] directly for auth concerns.
class AuthService extends ChangeNotifier {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const _rememberedEmailKey = 'remembered_email';

  AppUser? currentUser;

  Future<String?> loadRememberedEmail() {
    return DatabaseHelper.instance.getSetting(_rememberedEmailKey);
  }

  Future<LoginResult> login(
    String email,
    String password, {
    required bool rememberMe,
  }) async {
    final user = await DatabaseHelper.instance.getUserByEmail(email);
    final success =
        user != null && PasswordHasher.verify(password, user.passwordHash);

    await DatabaseHelper.instance.insertLoginAttempt(email, success);

    if (rememberMe) {
      await DatabaseHelper.instance.setSetting(_rememberedEmailKey, email);
    } else {
      await DatabaseHelper.instance.deleteSetting(_rememberedEmailKey);
    }

    if (!success) {
      return LoginResult.failure(
        user == null
            ? LoginFailureReason.notFound
            : LoginFailureReason.wrongPassword,
      );
    }

    currentUser = user;
    notifyListeners();
    return LoginResult.success(user);
  }

  Future<bool> register(AppUser user) async {
    final existing = await DatabaseHelper.instance.getUserByEmail(user.email);
    if (existing != null) return false;
    await DatabaseHelper.instance.insertUser(user);
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null) return false;
    if (!PasswordHasher.verify(currentPassword, user.passwordHash)) {
      return false;
    }
    final newHash = PasswordHasher.hash(newPassword);
    await DatabaseHelper.instance.updatePasswordHash(user.email, newHash);
    currentUser = AppUser(
      id: user.id,
      businessType: user.businessType,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      passwordHash: newHash,
      createdAt: user.createdAt,
    );
    notifyListeners();
    return true;
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;
    await DatabaseHelper.instance.deleteUserByEmail(user.email);
    await DatabaseHelper.instance.deleteSetting(_rememberedEmailKey);
    logout();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}
