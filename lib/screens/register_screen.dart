import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/password_hasher.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/brand_header.dart';

const String _aydinlatmaMetni =
    'Kişisel verileriniz (ad, soyad, e-posta, telefon ve iş bilgileriniz) '
    '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında ZanhaPay '
    'Mobil Pos hizmetlerinin sunulması, üyelik işlemlerinizin yürütülmesi ve '
    'yasal yükümlülüklerin yerine getirilmesi amacıyla işlenir. Verileriniz '
    'yalnızca hizmetin gerektirdiği ölçüde üçüncü taraf ödeme altyapısı '
    'sağlayıcılarıyla paylaşılabilir ve mevzuatın öngördüğü süre boyunca '
    'saklanır. Dilediğiniz zaman verilerinizin silinmesini talep edebilirsiniz.';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passRepeatCtrl = TextEditingController();
  late final TapGestureRecognizer _aydinlatmaRecognizer;

  String? _businessType;
  bool _obscurePass = true;
  bool _obscureRepeat = true;
  bool _acceptedNotice = false;
  bool _autovalidate = false;
  bool _submitting = false;

  static const _businessTypes = [
    'Şahıs Şirketi',
    'Limited Şirket',
    'Anonim Şirket',
    'Serbest Meslek',
  ];

  @override
  void initState() {
    super.initState();
    _aydinlatmaRecognizer = TapGestureRecognizer()..onTap = _showAydinlatma;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _passRepeatCtrl.dispose();
    _aydinlatmaRecognizer.dispose();
    super.dispose();
  }

  void _showAydinlatma() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aydınlatma Metni',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(_aydinlatmaMetni, style: TextStyle(height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anladım'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = true);
    final valid = _formKey.currentState!.validate();
    if (!valid || !_acceptedNotice) {
      if (!_acceptedNotice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen aydınlatma metnini okuyup onaylayın.'),
          ),
        );
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final created = await AuthService.instance.register(
        AppUser(
          businessType: _businessType!,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim().toLowerCase(),
          phone: _phoneCtrl.text.trim(),
          passwordHash: PasswordHasher.hash(_passCtrl.text),
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      if (!created) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu e-posta adresi zaten kayıtlı.')),
        );
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Üyeliğiniz oluşturuldu.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? v, String message) {
    if (v == null || v.trim().isEmpty) return message;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: Icon(Icons.arrow_back, color: palette.textPrimary),
                    ),
                    const Spacer(),
                    const ZanhaLogo(),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                const BrandWelcomeHeader(title: 'Hoş geldiniz'),
                const SizedBox(height: 24),
                const Text(
                  'Yeni Üye Ol',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _businessType,
                  decoration:
                      const InputDecoration(labelText: 'Ticari Tipinizi Seçiniz'),
                  items: _businessTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _businessType = v),
                  validator: (v) => v == null ? 'Ticari tipinizi seçiniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'Adınız'),
                  validator: (v) => _required(v, 'Adınızı giriniz'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Soyadınız',
                  ),
                  validator: (v) => _required(v, 'Soyadınızı giriniz'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'E-Posta Adresiniz'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'E-posta adresinizi giriniz';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                      return 'Geçerli bir e-posta giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Telefon Numaranız'),
                  validator: (v) => _required(v, 'Telefon numaranızı giriniz'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: palette.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
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
                    if (!hasUpper || !hasLower) {
                      return 'En az bir büyük bir küçük harf olmalıdır';
                    }
                    if (!hasDigit || !hasSpecial) {
                      return 'Rakam ve özel karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passRepeatCtrl,
                  obscureText: _obscureRepeat,
                  decoration: InputDecoration(
                    labelText: 'Şifre (Tekrar)',
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
                      v != _passCtrl.text ? 'Şifreler eşleşmiyor' : null,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.pendingBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.pendingBlue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info, color: AppColors.pendingBlue),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '1. Şifreniz en az 12 karakter olmalıdır.\n'
                          '2. En az bir büyük bir küçük harf olmalıdır.\n'
                          '3. Rakam ve özel karakter olmalıdır.',
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptedNotice,
                        onChanged: (v) =>
                            setState(() => _acceptedNotice = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Aydınlatma',
                              recognizer: _aydinlatmaRecognizer,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' metnini okudum'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
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
                      : const Text('Yeni Üye Ol'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
