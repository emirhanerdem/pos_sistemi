import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../models/payment_request.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../services/money_formatter.dart';
import '../services/payment_reference.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/status_badge.dart';

class PaymentRequestsScreen extends StatefulWidget {
  const PaymentRequestsScreen({super.key});

  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen> {
  PaymentRequestStatus? _filter = PaymentRequestStatus.pending;
  late Future<List<PaymentRequest>> _future = _load();

  Future<List<PaymentRequest>> _load() =>
      DatabaseHelper.instance.getPaymentRequests(status: _filter);

  Future<void> _reload() async {
    final data = await _load();
    if (!mounted) return;
    setState(() {
      _future = Future.value(data);
    });
  }

  /// Approving a request books it as a successful collection so it shows up
  /// in the transaction list and the daily turnover.
  Future<void> _approve(PaymentRequest request) async {
    final db = DatabaseHelper.instance;
    await db.insertTransaction(
      PosTransaction(
        paymentNumber: generatePaymentNumber(),
        customerName: request.customerName,
        date: DateTime.now(),
        type: 'Başarılı',
        amount: request.amount,
        status: TransactionStatus.success,
        channel: PosChannel.sanal,
        currency: request.currency,
        cardNumberMasked: '**** **** **** ****',
        cardBrand: 'Ödeme İsteği',
        source: 'PaymentRequest',
      ),
    );
    await db.updatePaymentRequestStatus(
      request.id!,
      PaymentRequestStatus.approved,
    );
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${request.customerName} tahsilatı onaylandı.'),
      ),
    );
  }

  Future<void> _reject(PaymentRequest request) async {
    await DatabaseHelper.instance.updatePaymentRequestStatus(
      request.id!,
      PaymentRequestStatus.rejected,
    );
    await _reload();
  }

  Future<void> _openNewRequestSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NewRequestSheet(),
    );
    if (created != true) return;
    setState(() => _filter = PaymentRequestStatus.pending);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme İstekleri'),
        actions: [
          IconButton(
            tooltip: 'Yeni İstek',
            icon: const Icon(Icons.add),
            onPressed: _openNewRequestSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip('Bekleyen', PaymentRequestStatus.pending),
                  _filterChip('Onaylanan', PaymentRequestStatus.approved),
                  _filterChip('Reddedilen', PaymentRequestStatus.rejected),
                  _filterChip('Tümü', null),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<PaymentRequest>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Bu durumda ödeme isteği bulunmuyor.',
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: context.palette.divider),
                      itemBuilder: (_, i) => _RequestTile(
                        request: items[i],
                        onApprove: _approve,
                        onReject: _reject,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, PaymentRequestStatus? status) {
    final selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? Colors.white : context.palette.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: context.accent,
        backgroundColor: context.palette.surface,
        side: BorderSide(color: context.palette.border),
        onSelected: (_) {
          setState(() => _filter = status);
          _reload();
        },
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final PaymentRequest request;
  final ValueChanged<PaymentRequest> onApprove;
  final ValueChanged<PaymentRequest> onReject;

  const _RequestTile({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  String _shareText() {
    return 'Sayın ${request.customerName}, '
        '${formatMoney(request.amount, request.currency)} tutarındaki ödeme '
        'isteğiniz için ZanhaPay üzerinden ödeme yapabilirsiniz.'
        '${request.note.isEmpty ? '' : '\nAçıklama: ${request.note}'}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pending = request.status == PaymentRequestStatus.pending;
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Row(
        children: [
          Expanded(
            child: Text(
              request.customerName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Paylaş',
            icon: Icon(Icons.ios_share, size: 20, color: palette.textSecondary),
            onPressed: () => Share.share(_shareText()),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(request.date),
              style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
            ),
            if (request.note.isNotEmpty)
              Text(
                request.note,
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  formatMoneyWithSymbol(request.amount, request.currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                StatusBadge(
                  label: request.status.label,
                  color: request.status.color,
                ),
              ],
            ),
            if (pending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () => onReject(request),
                      child: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: () => onApprove(request),
                      child: const Text('Onayla'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!pending) return tile;

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => onReject(request),
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
            icon: Icons.close,
            label: 'Reddet',
            borderRadius: BorderRadius.circular(12),
            spacing: 4,
            padding: const EdgeInsets.symmetric(horizontal: 3),
          ),
          SlidableAction(
            onPressed: (_) => onApprove(request),
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Onayla',
            borderRadius: BorderRadius.circular(12),
            spacing: 4,
            padding: const EdgeInsets.symmetric(horizontal: 3),
          ),
        ],
      ),
      child: tile,
    );
  }
}

class _NewRequestSheet extends StatefulWidget {
  const _NewRequestSheet();

  @override
  State<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends State<_NewRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _currency = 'TRY';

  static const _currencies = ['TRY', 'USD', 'EUR'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await DatabaseHelper.instance.insertPaymentRequest(
      PaymentRequest(
        customerName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        amount: parseAmount(_amountCtrl.text)!,
        currency: _currency,
        date: DateTime.now(),
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yeni Ödeme İsteği',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Müşteri Adı'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Müşteri adı giriniz' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon (opsiyonel)',
              ),
            ),
            const SizedBox(height: 12),
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
                    onChanged: (v) =>
                        setState(() => _currency = v ?? _currency),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Açıklama (opsiyonel)',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('İsteği Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
