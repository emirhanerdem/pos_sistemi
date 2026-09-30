import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import 'change_password_screen.dart';
import 'help_screen.dart';
import 'login_attempts_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  Future<void> _confirmCloseAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hesabımı Kapat'),
        content: const Text(
          'Hesabınızı kapattığınızda üyelik bilgileriniz kalıcı olarak '
          'silinir. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Hesabımı Kapat',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await AuthService.instance.deleteAccount();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Üyeliğim')),
      body: ListView(
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: context.accent.withValues(alpha: 0.16),
                    child: Text(
                      user.firstName.isNotEmpty
                          ? user.firstName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: context.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _MembershipTile(
            icon: Icons.settings_outlined,
            label: 'Ayarlar',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          _MembershipTile(
            icon: Icons.verified_user_outlined,
            label: 'Başarılı/Başarısız Girişler',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginAttemptsScreen()),
              );
            },
          ),
          _MembershipTile(
            icon: Icons.password_outlined,
            label: 'Şifremi Değiştir',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          _MembershipTile(
            icon: Icons.chat_bubble_outline,
            label: 'Yardım',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
          _MembershipTile(
            icon: Icons.person_outline,
            label: 'Hesabımı Kapat',
            onTap: () => _confirmCloseAccount(context),
          ),
          _MembershipTile(
            icon: Icons.power_settings_new,
            label: 'Çıkış Yap',
            color: AppColors.errorRed,
            onTap: () {
              AuthService.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MembershipTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MembershipTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? context.palette.textPrimary;
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Icon(icon, color: tileColor),
          title: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: tileColor),
          ),
          trailing: Icon(Icons.chevron_right, color: context.palette.textSecondary),
        ),
        Divider(height: 1, color: context.palette.divider),
      ],
    );
  }
}
