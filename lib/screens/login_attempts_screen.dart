import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/login_attempt.dart';
import '../services/database_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

class LoginAttemptsScreen extends StatefulWidget {
  const LoginAttemptsScreen({super.key});

  @override
  State<LoginAttemptsScreen> createState() => _LoginAttemptsScreenState();
}

class _LoginAttemptsScreenState extends State<LoginAttemptsScreen> {
  late Future<List<LoginAttempt>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.getLoginAttempts();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Başarılı/Başarısız Girişler')),
      body: FutureBuilder<List<LoginAttempt>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final attempts = snapshot.data!;
          if (attempts.isEmpty) {
            return Center(
              child: Text(
                'Henüz bir giriş denemesi kaydedilmedi.',
                style: TextStyle(color: palette.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: attempts.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: palette.divider),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final color =
                  attempt.success ? AppColors.success : AppColors.errorRed;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                leading: Icon(
                  attempt.success
                      ? Icons.check_circle_outline
                      : Icons.highlight_off,
                  color: color,
                ),
                title: Text(
                  attempt.email,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(attempt.date),
                  style: TextStyle(color: palette.textSecondary),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    attempt.success ? 'Başarılı' : 'Başarısız',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
