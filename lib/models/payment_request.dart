import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PaymentRequestStatus { pending, approved, rejected }

extension PaymentRequestStatusX on PaymentRequestStatus {
  String get label {
    switch (this) {
      case PaymentRequestStatus.pending:
        return 'Bekliyor';
      case PaymentRequestStatus.approved:
        return 'Onaylandı';
      case PaymentRequestStatus.rejected:
        return 'Reddedildi';
    }
  }

  Color get color {
    switch (this) {
      case PaymentRequestStatus.pending:
        return AppColors.pendingBlue;
      case PaymentRequestStatus.approved:
        return AppColors.success;
      case PaymentRequestStatus.rejected:
        return AppColors.errorRed;
    }
  }
}

/// A collection request the merchant sends to a customer. Stays [pending]
/// until the merchant marks it approved (which books a POS transaction) or
/// rejected.
class PaymentRequest {
  final int? id;
  final String customerName;
  final String phone;
  final String note;
  final double amount;
  final String currency;
  final DateTime date;
  final PaymentRequestStatus status;

  const PaymentRequest({
    this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    this.phone = '',
    this.note = '',
    this.currency = 'TRY',
    this.status = PaymentRequestStatus.pending,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'phone': phone,
      'note': note,
      'amount': amount,
      'currency': currency,
      'date': date.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory PaymentRequest.fromMap(Map<String, Object?> map) {
    return PaymentRequest(
      id: map['id'] as int?,
      customerName: map['customer_name'] as String,
      phone: map['phone'] as String,
      note: map['note'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      status: PaymentRequestStatus.values.byName(map['status'] as String),
    );
  }
}
