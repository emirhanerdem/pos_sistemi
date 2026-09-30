import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../services/money_formatter.dart';
import '../services/payment_reference.dart';
import '../theme/app_palette.dart';
import 'payment_success_screen.dart';

/// Merchant-presented QR flow: the merchant enters an amount, the customer
/// scans the generated code, then the merchant books the collection.
class QrPaymentScreen extends StatefulWidget {
  const QrPaymentScreen({super.key});

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _PendingQr {
  final double amount;
  final String currency;
  final String description;
  final String paymentNumber;

  const _PendingQr({
    required this.amount,
    required this.currency,
    required this.description,
    required this.paymentNumber,
  });

  String get payload =>
      'https://pay.zanhapay.com/qr/$paymentNumber'
      '?amount=${amount.toStringAsFixed(2)}&currency=$currency';
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _currency = 'TRY';
  _PendingQr? _pending;
  bool _saving = false;

  static const _currencies = ['TRY', 'USD', 'EUR'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _pending = _PendingQr(
        amount: parseAmount(_amountCtrl.text)!,
        currency: _currency,
        description: _descriptionCtrl.text.trim(),
        paymentNumber: generatePaymentNumber(),
      );
    });
  }

  Future<void> _collect() async {
    final pending = _pending!;
    setState(() => _saving = true);

    final customerName =
        pending.description.isEmpty ? 'QR Müşterisi' : pending.description;
    await DatabaseHelper.instance.insertTransaction(
      PosTransaction(
        paymentNumber: pending.paymentNumber,
        customerName: customerName,
        date: DateTime.now(),
        type: 'Başarılı',
        amount: pending.amount,
        status: TransactionStatus.success,
        channel: PosChannel.soft,
        currency: pending.currency,
        cardNumberMasked: '**** **** **** ****',
        cardBrand: 'QR Ödeme',
        source: 'QR',
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          amount: pending.amount,
          currency: pending.currency,
          cardNumberMasked: '**** **** **** ****',
          cardHolderName: customerName,
          cardBrand: 'QR Ödeme',
          paymentId: pending.paymentNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR İşlemleri')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _pending == null ? _buildForm() : _buildQr(_pending!),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tahsilat tutarını girin, müşteriniz oluşturulan QR kodu '
            'okutarak ödemesini tamamlasın.',
            style: TextStyle(
              color: context.palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Tutar'),
                  validator: (v) {
                    final amount = parseAmount(v ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Geçerli bir tutar giriniz';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: ''),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v ?? _currency),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(
              labelText: 'Açıklama (opsiyonel)',
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _generate,
            child: const Text('QR Kod Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildQr(_PendingQr pending) {
    final palette = context.palette;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: QrImageView(
            data: pending.payload,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          formatMoneyWithSymbol(pending.amount, pending.currency),
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (pending.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            pending.description,
            style: TextStyle(color: palette.textSecondary),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Ödeme No: ${pending.paymentNumber}',
          style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(color: palette.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => Share.share(pending.payload),
                child: const Text('Paylaş'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(color: palette.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => setState(() => _pending = null),
                child: const Text('Yeni QR'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saving ? null : _collect,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ödemeyi Tamamla'),
        ),
      ],
    );
  }
}
