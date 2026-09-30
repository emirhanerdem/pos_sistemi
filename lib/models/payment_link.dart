import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PaymentLinkStatus { active, paid, cancelled }

extension PaymentLinkStatusX on PaymentLinkStatus {
  String get label {
    switch (this) {
      case PaymentLinkStatus.active:
        return 'Aktif';
      case PaymentLinkStatus.paid:
        return 'Ödendi';
      case PaymentLinkStatus.cancelled:
        return 'İptal';
    }
  }

  Color get color {
    switch (this) {
      case PaymentLinkStatus.active:
        return AppColors.pendingBlue;
      case PaymentLinkStatus.paid:
        return AppColors.success;
      case PaymentLinkStatus.cancelled:
        return AppColors.errorRed;
    }
  }
}

/// A shareable collection link. [token] is the public part of the URL the
/// customer opens; an expired link stays [PaymentLinkStatus.active] in the
/// database and is reported as expired through [isExpired].
class PaymentLink {
  final int? id;
  final String title;
  final String customerName;
  final double amount;
  final String currency;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final PaymentLinkStatus status;

  const PaymentLink({
    this.id,
    required this.title,
    required this.amount,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.customerName = '',
    this.currency = 'TRY',
    this.status = PaymentLinkStatus.active,
  });

  String get url => 'https://pay.zanhapay.com/l/$token';

  bool get isExpired =>
      status == PaymentLinkStatus.active && expiresAt.isBefore(DateTime.now());

  String get statusLabel => isExpired ? 'Süresi Doldu' : status.label;

  Color get statusColor => isExpired ? AppColors.orange : status.color;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'customer_name': customerName,
      'amount': amount,
      'currency': currency,
      'token': token,
      'created_at': createdAt.millisecondsSinceEpoch,
      'expires_at': expiresAt.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory PaymentLink.fromMap(Map<String, Object?> map) {
    return PaymentLink(
      id: map['id'] as int?,
      title: map['title'] as String,
      customerName: map['customer_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      token: map['token'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expires_at'] as int),
      status: PaymentLinkStatus.values.byName(map['status'] as String),
    );
  }
}
