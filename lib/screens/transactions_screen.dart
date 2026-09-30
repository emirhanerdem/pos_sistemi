import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/status_badge.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  TransactionStatus? _statusFilter;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<Object>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Widget option(String label, TransactionStatus? value) {
          final selected = _statusFilter == value;
          return ListTile(
            title: Text(label),
            trailing: selected
                ? Icon(Icons.check, color: sheetContext.accent)
                : null,
            onTap: () => Navigator.pop(sheetContext, value ?? _NoFilter()),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Duruma Göre Filtrele',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: sheetContext.palette.textPrimary,
                      ),
                    ),
                  ),
                ),
                option('Tümü', null),
                option('Başarılı', TransactionStatus.success),
                option('Bekleniyor', TransactionStatus.pending),
                option('İade', TransactionStatus.refunded),
                option('Başarısız', TransactionStatus.failed),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() {
      _statusFilter = selected is _NoFilter ? null : selected as TransactionStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Detayları'),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            icon: Icon(
              Icons.tune,
              color: _statusFilter != null
                  ? accent
                  : context.palette.textPrimary,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TabBar(
              controller: _tabController,
              labelColor: accent,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: accent,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Sanal POS'),
                Tab(text: 'Soft POS'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TransactionList(
            channel: PosChannel.sanal,
            statusFilter: _statusFilter,
          ),
          _TransactionList(
            channel: PosChannel.soft,
            statusFilter: _statusFilter,
          ),
        ],
      ),
    );
  }
}

/// Sentinel returned from the filter sheet to distinguish "no selection made
/// yet" (user dismissed the sheet, `null`) from "user explicitly chose 'Tümü'
/// to clear the filter".
class _NoFilter {}

class _TransactionList extends StatefulWidget {
  final PosChannel channel;
  final TransactionStatus? statusFilter;
  const _TransactionList({required this.channel, this.statusFilter});

  @override
  State<_TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<_TransactionList> {
  late Future<List<PosTransaction>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _TransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusFilter != widget.statusFilter) {
      _reload();
    }
  }

  Future<List<PosTransaction>> _load() {
    return DatabaseHelper.instance.getTransactions(
      channel: widget.channel,
      status: widget.statusFilter,
    );
  }

  Future<void> _reload() async {
    final data = await _load();
    if (!mounted) return;
    setState(() {
      _future = Future.value(data);
    });
  }

  Future<void> _updateStatus(
    PosTransaction item,
    TransactionStatus status,
    String type,
  ) async {
    await DatabaseHelper.instance.updateTransactionStatus(
      item.id!,
      status,
      type,
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PosTransaction>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Bu kanalda işlem bulunamadı.',
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
            itemBuilder: (context, index) => _TransactionTile(
              item: items[index],
              onCancel: (t) =>
                  _updateStatus(t, TransactionStatus.failed, 'İptal'),
              onRefundRequest: (t) =>
                  _updateStatus(t, TransactionStatus.refunded, 'İade'),
              onOpened: _reload,
            ),
          ),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PosTransaction item;
  final ValueChanged<PosTransaction> onCancel;
  final ValueChanged<PosTransaction> onRefundRequest;
  final VoidCallback onOpened;

  const _TransactionTile({
    required this.item,
    required this.onCancel,
    required this.onRefundRequest,
    required this.onOpened,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(item.date);
    final palette = context.palette;
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => onCancel(item),
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
            icon: Icons.cancel_outlined,
            label: 'İptal Et',
            borderRadius: BorderRadius.circular(12),
            spacing: 4,
            padding: const EdgeInsets.symmetric(horizontal: 3),
          ),
          SlidableAction(
            onPressed: (_) => onRefundRequest(item),
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            icon: Icons.replay_outlined,
            label: 'İade Talep Et',
            borderRadius: BorderRadius.circular(12),
            spacing: 4,
            padding: const EdgeInsets.symmetric(horizontal: 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: item),
            ),
          );
          onOpened();
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.customerName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right, color: palette.textSecondary),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
              ),
              Text(
                'İşlem Tipi : ${item.type}',
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '₺ ${NumberFormat('#,##0.00', 'tr_TR').format(item.amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge.transaction(item.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
