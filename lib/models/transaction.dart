import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TransactionStatus { success, failed, pending, refunded }

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.success:
        return 'Başarılı';
      case TransactionStatus.failed:
        return 'Başarısız';
      case TransactionStatus.pending:
        return 'Bekleniyor';
      case TransactionStatus.refunded:
        return 'İade';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.success:
        return AppColors.success;
      case TransactionStatus.failed:
        return AppColors.errorRed;
      case TransactionStatus.pending:
        return AppColors.pendingBlue;
      case TransactionStatus.refunded:
        return AppColors.orange;
    }
  }

}

enum PosChannel { sanal, soft }

class PosTransaction {
  final int? id;
  final String paymentNumber;
  final String customerName;
  final DateTime date;
  final String type;
  final double amount;
  final TransactionStatus status;
  final PosChannel channel;
  final int installmentCount;
  final String paymentType;
  final String currency;
  final String cardNumberMasked;
  final String cardBrand;
  final String source;

  const PosTransaction({
    this.id,
    required this.paymentNumber,
    required this.customerName,
    required this.date,
    required this.type,
    required this.amount,
    required this.status,
    required this.channel,
    this.installmentCount = 1,
    this.paymentType = 'Tek Çekim',
    this.currency = 'TRY',
    this.cardNumberMasked = '5269 11** **3308',
    this.cardBrand = 'Deniz Bank / Bonus',
    this.source = 'PayWithPortal',
  });

  PosTransaction copyWith({
    int? id,
    TransactionStatus? status,
    String? type,
  }) {
    return PosTransaction(
      id: id ?? this.id,
      paymentNumber: paymentNumber,
      customerName: customerName,
      date: date,
      type: type ?? this.type,
      amount: amount,
      status: status ?? this.status,
      channel: channel,
      installmentCount: installmentCount,
      paymentType: paymentType,
      currency: currency,
      cardNumberMasked: cardNumberMasked,
      cardBrand: cardBrand,
      source: source,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'payment_number': paymentNumber,
      'customer_name': customerName,
      'date': date.millisecondsSinceEpoch,
      'type': type,
      'amount': amount,
      'status': status.name,
      'channel': channel.name,
      'installment_count': installmentCount,
      'payment_type': paymentType,
      'currency': currency,
      'card_number_masked': cardNumberMasked,
      'card_brand': cardBrand,
      'source': source,
    };
  }

  factory PosTransaction.fromMap(Map<String, Object?> map) {
    return PosTransaction(
      id: map['id'] as int?,
      paymentNumber: map['payment_number'] as String,
      customerName: map['customer_name'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: TransactionStatus.values.byName(map['status'] as String),
      channel: PosChannel.values.byName(map['channel'] as String),
      installmentCount: map['installment_count'] as int,
      paymentType: map['payment_type'] as String,
      currency: map['currency'] as String,
      cardNumberMasked: map['card_number_masked'] as String,
      cardBrand: map['card_brand'] as String,
      source: map['source'] as String,
    );
  }
}
