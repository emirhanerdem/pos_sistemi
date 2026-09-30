import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../services/nfc_service.dart';
import 'card_payment_screen.dart';

enum _ScanState { idle, scanning, detected, error, unavailable }

class NfcPaymentScreen extends StatefulWidget {
  const NfcPaymentScreen({super.key});

  @override
  State<NfcPaymentScreen> createState() => _NfcPaymentScreenState();
}

class _NfcPaymentScreenState extends State<NfcPaymentScreen> {
  _ScanState _state = _ScanState.idle;
  NfcDetectionResult? _result;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    NfcService.stop();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() => _state = _ScanState.scanning);

    final available = await NfcService.isAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() => _state = _ScanState.unavailable);
      return;
    }

    final result = await NfcService.detectCard();
    if (!mounted) return;

    if (result == null) {
      setState(() => _state = _ScanState.error);
      return;
    }

    setState(() {
      _state = _ScanState.detected;
      _result = result;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _goToManualEntry();
  }

  void _goToManualEntry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CardPaymentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hızlı Ödeme')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              _Illustration(state: _state),
              const SizedBox(height: 28),
              Text(
                _headline(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.accent,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _description(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (_state == _ScanState.scanning) const _PulsingDots(),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Sorun\nyaşıyorsanız',
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.palette.textPrimary,
                      side: BorderSide(color: context.palette.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _goToManualEntry(),
                    child: const Text('Elle Girin'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _headline() {
    switch (_state) {
      case _ScanState.detected:
        return 'Kart Algılandı';
      case _ScanState.error:
        return 'Kart Okunamadı';
      case _ScanState.unavailable:
        return 'NFC Kullanılamıyor';
      default:
        return 'Kredi Kartınızı Telefonun\nArka Tarafına  Okutunuz.';
    }
  }

  String _description() {
    switch (_state) {
      case _ScanState.detected:
        return 'Kart kimliği: ${_result?.tagId ?? '-'}\nÖdeme ekranına yönlendiriliyorsunuz...';
      case _ScanState.error:
        return 'Kart okuma zaman aşımına uğradı. Tekrar deneyin ya da bilgilerinizi elle girin.';
      case _ScanState.unavailable:
        return 'Cihazınızın NFC özelliği kapalı veya desteklenmiyor. Kart bilgilerinizi elle girebilirsiniz.';
      default:
        return 'Telefonun NFC\n(temassız mobil ödeme)\nözelliği ile kredi kartınızı okutarak\nödeme alabilirsiniz.';
    }
  }
}

class _Illustration extends StatelessWidget {
  final _ScanState state;
  const _Illustration({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _ScanState.detected => AppColors.success,
      _ScanState.error || _ScanState.unavailable => AppColors.errorRed,
      _ => context.accent,
    };
    final icon = switch (state) {
      _ScanState.detected => Icons.check_circle,
      _ScanState.error || _ScanState.unavailable => Icons.nfc_outlined,
      _ => Icons.nfc,
    };
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
        ),
        Icon(icon, size: 64, color: color),
      ],
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final phase = (_controller.value * 4 - i) % 4;
            final active = phase >= 0 && phase < 1;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? context.accent : context.palette.border,
              ),
            );
          }),
        );
      },
    );
  }
}
