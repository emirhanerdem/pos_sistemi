import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/detail_row.dart';
import '../widgets/status_badge.dart';

class TransactionDetailScreen extends StatefulWidget {
  final PosTransaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late PosTransaction _transaction = widget.transaction;

  @override
  Widget build(BuildContext context) {
    final t = _transaction;
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(t.date);
    return Scaffold(
      appBar: AppBar(title: const Text('İşlem Detayları')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DetailSectionTitle(title: 'Ödeme Bilgileri'),
              DetailRow.text(
                'Net Tutar',
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(t.amount)}',
                highlight: true,
              ),
              DetailRow.text(
                'Taksit Sayısı',
                '${t.installmentCount}',
                highlight: true,
              ),
              DetailRow.text('Ödeme Türü', t.paymentType),
              DetailRow.text('Para Birimi', t.currency),
              DetailRow(
                label: 'Ödeme Durumu',
                value: StatusBadge.transaction(t.status),
              ),
              DetailRow.text('Kart Sahibi', t.customerName),
              DetailRow.text('Kart Numarası', t.cardNumberMasked),
              DetailRow.text('Kart Adı', t.cardBrand),
              DetailRow.text('İşlem Tarihi', dateStr, bold: true),
              DetailRow.text('İşlem Numarası', t.paymentNumber),
              DetailRow.text('İşlem Kaynağı', t.source),
              DetailRow.text('Hata Kodu', '----'),
              DetailRow.text('Hata Mesajı', '----'),
              const DetailSectionTitle(title: 'Kullanıcı Bilgileri'),
              DetailRow.text('Müşteri Kimlik Numarası', '----'),
              DetailRow.text('Müşteri Ad/ Soyad', '----'),
              DetailRow.text('Müşteri Eposta Adresi', '----'),
              DetailRow.text('Müşteri Telefon Numarası', '----'),
              DetailRow.text('Müşteri Adresi', '----'),
              const DetailSectionTitle(title: 'Firma Bilgileri'),
              DetailRow.text('Üye İşyeri Sunucu Ip', '----'),
              DetailRow.text('Müşteri İşlemci Ip', '----'),
              DetailRow.text('Üye İşyeri Komisyon Oranı', '----'),
              DetailRow.text('Üye İşyeri Komisyon Tutarı', '----'),
              DetailRow.text('Üye İşyeri Ödenecek toplam Tutar', '----'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                  ),
                  onPressed: () => _confirm(
                    action: 'İptal Et',
                    status: TransactionStatus.failed,
                    type: 'İptal',
                  ),
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('İptal Et'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                  ),
                  onPressed: () => _confirm(
                    action: 'İade Talep Et',
                    status: TransactionStatus.refunded,
                    type: 'İade',
                  ),
                  icon: const Icon(Icons.replay_outlined, size: 20),
                  label: const Text('İade Talep Et'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: context.palette.textPrimary,
                    side: BorderSide(color: context.palette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _showReceipt,
                  child: const Text('Dekont Görüntüle'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceipt() {
    final t = _transaction;
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(t.date);
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
              'Dekont',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'Kart Sahibi: ${t.customerName}\n'
              'İşlem Tarihi: $dateStr\n'
              'Tutar: ₺${NumberFormat('#,##0.00', 'tr_TR').format(t.amount)}\n'
              'Taksit Sayısı: ${t.installmentCount}\n'
              'İşlem Numarası: ${t.paymentNumber}\n'
              'Kart Numarası: ${t.cardNumberMasked}\n'
              'Durum: ${t.status.label}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm({
    required String action,
    required TransactionStatus status,
    required String type,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action),
        content: Text('$action işlemini onaylıyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await DatabaseHelper.instance.updateTransactionStatus(
      _transaction.id!,
      status,
      type,
    );
    if (!mounted) return;
    setState(() {
      _transaction = _transaction.copyWith(status: status, type: type);
    });
  }
}
