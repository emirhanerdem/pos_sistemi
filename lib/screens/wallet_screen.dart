import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_request.dart';
import '../models/transaction.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/money_formatter.dart';
import '../theme/app_palette.dart';
import '../widgets/brand_header.dart';
import '../widgets/status_badge.dart';
import 'card_payment_screen.dart';
import 'help_screen.dart';
import 'nfc_payment_screen.dart';
import 'payment_link_screen.dart';
import 'payment_requests_screen.dart';
import 'qr_payment_screen.dart';
import 'transaction_detail_screen.dart';
import 'transactions_screen.dart';

enum _Period { day, week, month }

extension _PeriodX on _Period {
  String get label {
    switch (this) {
      case _Period.day:
        return 'Bugün';
      case _Period.week:
        return 'Bu Hafta';
      case _Period.month:
        return 'Bu Ay';
    }
  }
}

class _DayBar {
  final DateTime day;
  final double total;
  const _DayBar({required this.day, required this.total});
}

class _WalletData {
  final Map<_Period, double> turnover;
  final Map<_Period, int> count;
  final List<_DayBar> week;
  final int pendingCount;
  final double pendingTotal;
  final List<PosTransaction> recent;

  const _WalletData({
    required this.turnover,
    required this.count,
    required this.week,
    required this.pendingCount,
    required this.pendingTotal,
    required this.recent,
  });
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<_WalletData> _future = _load();
  _Period _period = _Period.day;

  Future<_WalletData> _load() async {
    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month);

    final transactions = await db.getTransactions();
    final successful =
        transactions.where((t) => t.status == TransactionStatus.success);

    int countFrom(DateTime from) => successful
        .where((t) => !t.date.isBefore(from) && t.date.isBefore(endOfDay))
        .length;

    final week = List.generate(7, (i) {
      final day = startOfDay.subtract(Duration(days: 6 - i));
      final next = day.add(const Duration(days: 1));
      final total = successful
          .where((t) => !t.date.isBefore(day) && t.date.isBefore(next))
          .fold(0.0, (sum, t) => sum + t.amount);
      return _DayBar(day: day, total: total);
    });

    final pending =
        await db.getPaymentRequests(status: PaymentRequestStatus.pending);

    return _WalletData(
      turnover: {
        _Period.day: await db.getTurnover(from: startOfDay, to: endOfDay),
        _Period.week: await db.getTurnover(from: startOfWeek, to: endOfDay),
        _Period.month: await db.getTurnover(from: startOfMonth, to: endOfDay),
      },
      count: {
        _Period.day: countFrom(startOfDay),
        _Period.week: countFrom(startOfWeek),
        _Period.month: countFrom(startOfMonth),
      },
      week: week,
      pendingCount: pending.length,
      pendingTotal: pending.fold(0.0, (total, r) => total + r.amount),
      recent: transactions.take(3).toList(),
    );
  }

  Future<void> _reload() async {
    final data = await _load();
    if (!mounted) return;
    setState(() {
      _future = Future.value(data);
    });
  }

  /// Sub-screens can book transactions or resolve requests, so everything on
  /// this page is refreshed whenever one of them pops.
  Future<void> _openAndReload(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_WalletData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                children: [
                  const _Header(),
                  const SizedBox(height: 20),
                  _SummaryCard(
                    data: data,
                    period: _period,
                    onPeriodChanged: (p) => setState(() => _period = p),
                  ),
                  if (data.pendingCount > 0) ...[
                    const SizedBox(height: 12),
                    _PendingBanner(
                      count: data.pendingCount,
                      total: data.pendingTotal,
                      onTap: () =>
                          _openAndReload(const PaymentRequestsScreen()),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Tahsilat Al'),
                  const SizedBox(height: 12),
                  _PrimaryAction(
                    onTap: () => _openAndReload(const NfcPaymentScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ActionGrid(onOpen: _openAndReload),
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: 'Son İşlemler',
                    action: 'Tümü',
                    onAction: () => _openAndReload(const TransactionsScreen()),
                  ),
                  const SizedBox(height: 8),
                  _RecentList(
                    items: data.recent,
                    onOpened: _reload,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final palette = context.palette;
    return Row(
      children: [
        const ZanhaLogo(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user == null ? 'Merhaba' : 'Merhaba, ${user.firstName}',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                user?.businessType ?? 'ZanhaPay Mobil Pos',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Yardım',
          icon: Icon(Icons.info_outline, color: palette.textSecondary),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _WalletData data;
  final _Period period;
  final ValueChanged<_Period> onPeriodChanged;

  const _SummaryCard({
    required this.data,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final turnover = data.turnover[period]!;
    final earnings = turnover * (1 - DatabaseHelper.commissionRate);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodSelector(selected: period, onChanged: onPeriodChanged),
          const SizedBox(height: 18),
          Text(
            'Ciro',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoneyWithSymbol(turnover),
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Hakediş',
                  value: formatMoney(earnings),
                ),
              ),
              Container(width: 1, height: 30, color: palette.divider),
              Expanded(
                child: _MiniStat(
                  icon: Icons.receipt_long_outlined,
                  label: 'İşlem',
                  value: '${data.count[period]} adet',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _WeekChart(bars: data.week),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: _Period.values.map((p) {
          final active = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? context.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    color: active ? Colors.white : palette.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Icon(icon, size: 18, color: palette.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Seven-day turnover bars. Heights are relative to the best day in the
/// window, so an all-zero week renders as flat placeholders rather than
/// dividing by zero.
class _WeekChart extends StatelessWidget {
  final List<_DayBar> bars;
  const _WeekChart({required this.bars});

  static const _dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final peak = bars.fold(0.0, (max, b) => b.total > max ? b.total : max);
    final today = bars.last.day;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son 7 gün',
          style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 58,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((bar) {
              final isToday = bar.day == today;
              final ratio = peak == 0 ? 0.0 : bar.total / peak;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 14,
                      height: 5 + 30 * ratio,
                      decoration: BoxDecoration(
                        color: isToday
                            ? context.accent
                            : context.accent.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _dayNames[bar.day.weekday - 1],
                      style: TextStyle(
                        color: isToday
                            ? palette.textPrimary
                            : palette.textSecondary,
                        fontSize: 10.5,
                        fontWeight:
                            isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;

  const _PendingBanner({
    required this.count,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8A3FFC);
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count bekleyen ödeme isteği',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Toplam ${formatMoney(total)} onayınızı bekliyor',
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  action!,
                  style: TextStyle(
                    color: context.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: context.accent),
              ],
            ),
          ),
      ],
    );
  }
}

/// NFC collection is the everyday action, so it gets the full-width slot
/// above the rest of the payment methods.
class _PrimaryAction extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF4650D);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.tap_and_play,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hızlı Ödeme',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kartı telefona okutarak saniyeler içinde tahsil edin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final Future<void> Function(Widget screen) onOpen;
  const _ActionGrid({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      // Nested scroll views default to `primary: true`, which would otherwise
      // pad this grid with the device's safe-area insets.
      primary: false,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _ActionCard(
          color: const Color(0xFF19C68A),
          icon: Icons.credit_card,
          title: 'Kredi Kartı',
          subtitle: 'Bilgileri elle girin',
          onTap: () => onOpen(const CardPaymentScreen()),
        ),
        _ActionCard(
          color: const Color(0xFFF6B32C),
          icon: Icons.qr_code_2,
          title: 'QR ile Tahsilat',
          subtitle: 'Müşteri okutsun',
          onTap: () => onOpen(const QrPaymentScreen()),
        ),
        _ActionCard(
          color: const Color(0xFF3B82F6),
          icon: Icons.link,
          title: 'Ödeme Linki',
          subtitle: 'Uzaktan tahsilat',
          onTap: () => onOpen(const PaymentLinkScreen()),
        ),
        _ActionCard(
          color: const Color(0xFF8A3FFC),
          icon: Icons.payments_outlined,
          title: 'Ödeme İstekleri',
          subtitle: 'Onayla veya reddet',
          onTap: () => onOpen(const PaymentRequestsScreen()),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  final List<PosTransaction> items;
  final VoidCallback onOpened;

  const _RecentList({required this.items, required this.onOpened});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          'Henüz işlem yok. İlk tahsilatınızı yukarıdan alın.',
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
      );
    }
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailScreen(transaction: item),
                  ),
                );
                onOpened();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item.status.color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconFor(item.source),
                        size: 19,
                        color: item.status.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(item.date),
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatMoneyWithSymbol(item.amount, item.currency),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge.transaction(item.status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(String source) {
    switch (source) {
      case 'QR':
        return Icons.qr_code_2;
      case 'PaymentLink':
        return Icons.link;
      case 'PaymentRequest':
        return Icons.payments_outlined;
      default:
        return Icons.credit_card;
    }
  }
}
