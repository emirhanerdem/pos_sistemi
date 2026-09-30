import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../services/money_formatter.dart';
import '../services/payment_reference.dart';
import '../theme/app_palette.dart';
import 'payment_success_screen.dart';

class CardPaymentScreen extends StatefulWidget {
  final String? prefilledCardNumber;
  final String? prefilledCardName;

  const CardPaymentScreen({
    super.key,
    this.prefilledCardNumber,
    this.prefilledCardName,
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 16; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _cardNumberCtrl =
      TextEditingController(text: widget.prefilledCardNumber ?? '');
  late final _cardNameCtrl =
      TextEditingController(text: widget.prefilledCardName ?? '');
  final _amountCtrl = TextEditingController();

  String? _month;
  String? _year;
  final _cvcCtrl = TextEditingController();
  String _currency = 'TRY';

  static final _months =
      List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
  static final _years =
      List.generate(12, (i) => (DateTime.now().year + i).toString());
  static const _currencies = ['TRY', 'USD', 'EUR'];

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _amountCtrl.dispose();
    _cvcCtrl.dispose();
    super.dispose();
  }

  Future<void> _viewInstallments() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final amount = parseAmount(_amountCtrl.text) ?? 0;
    final cardHolderName =
        _cardNameCtrl.text.isEmpty ? 'Kart Sahibi' : _cardNameCtrl.text;
    final paymentNumber = generatePaymentNumber();
    const installmentCount = 2;

    await DatabaseHelper.instance.insertTransaction(
      PosTransaction(
        paymentNumber: paymentNumber,
        customerName: cardHolderName,
        date: DateTime.now(),
        type: 'Başarılı',
        amount: amount,
        status: TransactionStatus.success,
        channel: PosChannel.soft,
        installmentCount: installmentCount,
        paymentType: installmentCount > 1 ? 'Taksit' : 'Tek Çekim',
        currency: _currency,
        cardNumberMasked: _maskedCardNumber(),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          amount: amount,
          currency: _currency,
          installmentCount: installmentCount,
          cardNumberMasked: _maskedCardNumber(),
          cardHolderName: cardHolderName,
          paymentId: paymentNumber,
        ),
      ),
    );
  }

  String _maskedCardNumber() {
    final digits = _cardNumberCtrl.text.replaceAll(' ', '');
    if (digits.length < 10) return '**** **** **** ****';
    return '${digits.substring(0, 6)}** **${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kredi Kartı ile Öde')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CardNumberFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Kart Numarası',
                    suffixIcon: Icon(
                      Icons.credit_card,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(' ', '');
                    if (digits.length < 16) return 'Geçerli bir kart numarası giriniz';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardNameCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kart Üzerindeki Ad ve Soyad',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ad ve soyad giriniz' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _month,
                        decoration: const InputDecoration(labelText: 'Ay'),
                        items: _months
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => _month = v),
                        validator: (v) => v == null ? '' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _year,
                        decoration: const InputDecoration(labelText: 'Yıl'),
                        items: _years
                            .map((y) =>
                                DropdownMenuItem(value: y, child: Text(y)))
                            .toList(),
                        onChanged: (v) => setState(() => _year = v),
                        validator: (v) => v == null ? '' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _cvcCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        buildCounter: (context,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            null,
                        decoration: const InputDecoration(labelText: 'CVC'),
                        validator: (v) => (v == null || v.length < 3)
                            ? ''
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Tutar'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Tutar giriniz'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(labelText: ''),
                        items: _currencies
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _currency = v ?? _currency),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _viewInstallments,
                  child: const Text('Taksitleri Görüntüle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
