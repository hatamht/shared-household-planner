import 'package:equatable/equatable.dart';
import '../../../../features/auth/domain/entities/cloud_schema.dart';

/// Type of remote change notification
enum RemoteChangeType {
  added,
  modified,
  removed,
}

/// Represents a real-time remote bill modification event received from Firestore
class RemoteBillChange extends Equatable {
  final String id;
  final String projectId;
  final RemoteChangeType type;
  final String payerName;
  final String description;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final CloudBill? bill;

  const RemoteBillChange({
    required this.id,
    required this.projectId,
    required this.type,
    required this.payerName,
    required this.description,
    required this.amount,
    this.currency = 'VND',
    required this.timestamp,
    this.bill,
  });

  bool get isAdded => type == RemoteChangeType.added;
  bool get isModified => type == RemoteChangeType.modified;
  bool get isRemoved => type == RemoteChangeType.removed;

  /// Helper to format localized notification text
  /// e.g. "Minh vừa thêm chi tiêu: 50.000đ [Taxi]"
  String formatMessage({
    required String addedTemplate,
    required String updatedTemplate,
    required String removedTemplate,
    String? formattedAmount,
  }) {
    final amtStr = formattedAmount ?? '${amount.toStringAsFixed(0)}$currency';
    switch (type) {
      case RemoteChangeType.added:
        return addedTemplate
            .replaceAll('{user}', payerName.isNotEmpty ? payerName : 'Thành viên')
            .replaceAll('{amount}', amtStr)
            .replaceAll('{description}', description);
      case RemoteChangeType.modified:
        return updatedTemplate
            .replaceAll('{user}', payerName.isNotEmpty ? payerName : 'Thành viên')
            .replaceAll('{amount}', amtStr)
            .replaceAll('{description}', description);
      case RemoteChangeType.removed:
        return removedTemplate
            .replaceAll('{user}', payerName.isNotEmpty ? payerName : 'Thành viên')
            .replaceAll('{description}', description);
    }
  }

  RemoteBillChange copyWith({
    String? id,
    String? projectId,
    RemoteChangeType? type,
    String? payerName,
    String? description,
    double? amount,
    String? currency,
    DateTime? timestamp,
    CloudBill? bill,
  }) {
    return RemoteBillChange(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      payerName: payerName ?? this.payerName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
      bill: bill ?? this.bill,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'projectId': projectId,
        'type': type.name,
        'payerName': payerName,
        'description': description,
        'amount': amount,
        'currency': currency,
        'timestamp': timestamp.toIso8601String(),
        'bill': bill?.toMap(),
      };

  factory RemoteBillChange.fromMap(Map<String, dynamic> map) => RemoteBillChange(
        id: map['id'] as String,
        projectId: map['projectId'] as String,
        type: RemoteChangeType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => RemoteChangeType.added,
        ),
        payerName: map['payerName'] as String? ?? '',
        description: map['description'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String? ?? 'VND',
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        bill: map['bill'] != null
            ? CloudBill.fromMap(
                Map<String, dynamic>.from(map['bill'] as Map),
                map['id'] as String,
              )
            : null,
      );

  factory RemoteBillChange.fromCloudBill({
    required CloudBill bill,
    required RemoteChangeType type,
  }) {
    return RemoteBillChange(
      id: bill.id,
      projectId: bill.projectId,
      type: type,
      payerName: bill.payerName.isNotEmpty ? bill.payerName : bill.payerId,
      description: bill.description,
      amount: bill.amount,
      timestamp: bill.updatedAt,
      bill: bill,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        type,
        payerName,
        description,
        amount,
        currency,
        timestamp,
        bill,
      ];
}
