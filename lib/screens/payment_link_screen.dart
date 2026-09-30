import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../models/payment_link.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../services/money_formatter.dart';
import '../services/payment_reference.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/status_badge.dart';

class PaymentLinkScreen extends StatefulWidget {
  const PaymentLinkScreen({super.key});

  @override
  State<PaymentLinkScreen> createState() => _PaymentLinkScreenState();
}

class _PaymentLinkScreenState extends State<PaymentLinkScreen> {
  late Future<List<PaymentLink>> _future = DatabaseHelper.instance
      .getPaymentLinks();

  Future<void> _reload() async {
    final data = await DatabaseHelper.instance.getPaymentLinks();
    if (!mounted) return;
    setState(() {
      _future = Future.value(data);
    });
  }

  Future<void> _createLink() async {
    final link = await showModalBottomSheet<PaymentLink>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NewLinkSheet(),
    );
    if (link == null) return;
    await DatabaseHelper.instance.insertPaymentLink(link);
    await _reload();
    if (!mounted) return;
    await _showLinkDialog(link);
  }

  Future<void> _showLinkDialog(PaymentLink link) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ödeme Linki Hazır'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${link.title} · '
              '${formatMoney(link.amount, link.currency)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SelectableText(
              link.url,
              style: TextStyle(color: dialogContext.accent, fontSize: 13.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _copy(link),
            child: const Text('Kopyala'),
          ),
          TextButton(
            onPressed: () => Share.share(_shareText(link)),
            child: const Text('Paylaş'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  String _shareText(PaymentLink link) {
    return '${link.title} için ${formatMoney(link.amount, link.currency)} '
        'tutarındaki ödemenizi aşağıdaki linkten yapabilirsiniz:\n${link.url}\n'
        'Son geçerlilik: ${DateFormat('dd.MM.yyyy').format(link.expiresAt)}';
  }

  Future<void> _copy(PaymentLink link) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ödeme linki kopyalandı.')),
    );
  }

  /// Marking a link paid books the collection, the same way approving a
  /// payment request does.
  Future<void> _markPaid(PaymentLink link) async {
    final db = DatabaseHelper.instance;
    await db.insertTransaction(
      PosTransaction(
        paymentNumber: generatePaymentNumber(),
        customerName:
            link.customerName.isEmpty ? link.title : link.customerName,
        date: DateTime.now(),
        type: 'Başarılı',
        amount: link.amount,
        status: TransactionStatus.success,
        channel: PosChannel.sanal,
        currency: link.currency,
        cardNumberMasked: '**** **** **** ****',
        cardBrand: 'Link ile Ödeme',
        source: 'PaymentLink',
      ),
    );
    await db.updatePaymentLinkStatus(link.id!, PaymentLinkStatus.paid);
    await _reload();
  }

  Future<void> _cancel(PaymentLink link) async {
    await DatabaseHelper.instance.updatePaymentLinkStatus(
      link.id!,
      PaymentLinkStatus.cancelled,
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link ile Ödeme'),
        actions: [
          IconButton(
            tooltip: 'Yeni Link',
            icon: const Icon(Icons.add),
            onPressed: _createLink,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<PaymentLink>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final links = snapshot.data!;
            if (links.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link, size: 56, color: context.accent),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz ödeme linki oluşturmadınız. Müşterinize '
                        'göndereceğiniz linki birkaç saniyede hazırlayın.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.palette.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _createLink,
                        child: const Text('Ödeme Linki Oluştur'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: links.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: context.palette.divider),
                itemBuilder: (_, i) => _LinkTile(
                  link: links[i],
                  onCopy: _copy,
                  onShare: (l) => Share.share(_shareText(l)),
                  onMarkPaid: _markPaid,
                  onCancel: _cancel,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final PaymentLink link;
  final ValueChanged<PaymentLink> onCopy;
  final ValueChanged<PaymentLink> onShare;
  final ValueChanged<PaymentLink> onMarkPaid;
  final ValueChanged<PaymentLink> onCancel;

  const _LinkTile({
    required this.link,
    required this.onCopy,
    required this.onShare,
    required this.onMarkPaid,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final actionable =
        link.status == PaymentLinkStatus.active && !link.isExpired;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  link.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              StatusBadge(label: link.statusLabel, color: link.statusColor),
            ],
          ),
          const SizedBox(height: 4),
          if (link.customerName.isNotEmpty)
            Text(
              link.customerName,
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
          Text(
            'Son geçerlilik: '
            '${DateFormat('dd.MM.yyyy').format(link.expiresAt)}',
            style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          Text(
            formatMoneyWithSymbol(link.amount, link.currency),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.accent, fontSize: 13),
                  ),
                ),
                InkWell(
                  onTap: () => onCopy(link),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.copy,
                      size: 18,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onShare(link),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.ios_share,
                      size: 18,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actionable) ...[
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
                    onPressed: () => onCancel(link),
                    child: const Text('İptal Et'),
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
                    onPressed: () => onMarkPaid(link),
                    child: const Text('Ödendi'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NewLinkSheet extends StatefulWidget {
  const _NewLinkSheet();

  @override
  State<_NewLinkSheet> createState() => _NewLinkSheetState();
}

class _NewLinkSheetState extends State<_NewLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _currency = 'TRY';
  int _validityDays = 7;

  static const _currencies = ['TRY', 'USD', 'EUR'];
  static const _validityOptions = [1, 7, 30];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _customerCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.pop(
      context,
      PaymentLink(
        title: _titleCtrl.text.trim(),
        customerName: _customerCtrl.text.trim(),
        amount: parseAmount(_amountCtrl.text)!,
        currency: _currency,
        token: generateLinkToken(),
        createdAt: now,
        expiresAt: now.add(Duration(days: _validityDays)),
      ),
    );
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
              'Yeni Ödeme Linki',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Link Başlığı'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Başlık giriniz' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerCtrl,
              decoration: const InputDecoration(
                labelText: 'Müşteri Adı (opsiyonel)',
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
            DropdownButtonFormField<int>(
              initialValue: _validityDays,
              decoration: const InputDecoration(labelText: 'Geçerlilik Süresi'),
              items: _validityOptions
                  .map(
                    (d) => DropdownMenuItem(value: d, child: Text('$d gün')),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _validityDays = v ?? 7),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Linki Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
