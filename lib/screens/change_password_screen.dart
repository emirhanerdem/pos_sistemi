import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_palette.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _repeatCtrl = TextEditingController();
  bool _submitting = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureRepeat = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _repeatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final ok = await AuthService.instance.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mevcut şifreniz hatalı.')),
        );
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreniz güncellendi.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Değiştir')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mevcut Şifre',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: palette.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Mevcut şifrenizi giriniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: palette.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 12) {
                      return 'Şifreniz en az 12 karakter olmalıdır';
                    }
                    final hasUpper = v.contains(RegExp(r'[A-Z]'));
                    final hasLower = v.contains(RegExp(r'[a-z]'));
                    final hasDigit = v.contains(RegExp(r'[0-9]'));
                    final hasSpecial =
                        v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'));
                    if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
                      return 'Büyük/küçük harf, rakam ve özel karakter içermeli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _repeatCtrl,
                  obscureText: _obscureRepeat,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre (Tekrar)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureRepeat
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: palette.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureRepeat = !_obscureRepeat),
                    ),
                  ),
                  validator: (v) =>
                      v != _newCtrl.text ? 'Şifreler eşleşmiyor' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Şifreyi Güncelle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
