import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/detail_row.dart';
import 'home_shell.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final String currency;
  final int installmentCount;
  final String cardNumberMasked;
  final String cardHolderName;
  final String merchantName;
  final String cardBrand;
  final String paymentId;

  PaymentSuccessScreen({
    super.key,
    required this.amount,
    this.currency = 'TRY',
    this.installmentCount = 1,
    this.cardNumberMasked = '5269 11** **3308',
    this.cardHolderName = 'Yaşar Aşık',
    this.merchantName = 'Zanha Grup',
    this.cardBrand = 'Deniz Bonus',
    String? paymentId,
  }) : paymentId = paymentId ?? 'adfa646as7';

  String get _currencySymbol => currency == 'TRY'
      ? '₺'
      : currency == 'USD'
          ? '\$'
          : '€';

  String _receiptText() {
    final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return 'Üye işyeri: $merchantName\n'
        'İşlem Tarihi: $dateStr\n'
        'Ödeme Tutarı: $_currencySymbol${amount.toStringAsFixed(2)}\n'
        'Taksit Sayısı: $installmentCount Taksit\n'
        'Ödeme Numarası: $paymentId\n'
        'Kart Sahibi Adı: $cardHolderName\n'
        'Kart Numarası: $cardNumberMasked\n'
        'Kart Adı: $cardBrand';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());
    final palette = context.palette;
    final accent = context.accent;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCE9EA),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(Icons.phone_android, size: 72, color: palette.textPrimary),
                  Positioned(
                    top: 18,
                    right: 28,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Ödeme Başarılı',
                style: TextStyle(
                  color: accent,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'İşlem Detayları',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              DetailRow.text('Üye işyeri', merchantName),
              DetailRow.text('İşem Tarihi', dateStr),
              DetailRow.text(
                'Ödeme Tutarı',
                '$_currencySymbol${amount.toStringAsFixed(2)}',
                highlight: true,
              ),
              DetailRow.text(
                'Taksit Sayısı',
                '$installmentCount Taksit',
                highlight: true,
              ),
              DetailRow.text('Ödeme Numarası', paymentId),
              DetailRow.text('Kart Sahibi Adı', cardHolderName),
              DetailRow.text('Kart Numarası', cardNumberMasked),
              DetailRow.text('Kart Adı', cardBrand),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dekont Bilgisini',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: palette.textPrimary,
                        side: BorderSide(color: palette.textPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dekont',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 12),
                                Text(_receiptText()),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('Görüntüle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Share.share(_receiptText());
                      },
                      child: const Text('Paylaş'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: palette.textPrimary,
                    side: BorderSide(color: palette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeShell()),
                      (route) => false,
                    );
                  },
                  child: const Text('Anasayfa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
