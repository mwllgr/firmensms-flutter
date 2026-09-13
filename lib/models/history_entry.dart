import 'sms_message.dart';
import 'sms_result.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.sentAt,
    required this.message,
    required this.success,
    this.error,
    this.result,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as String,
    sentAt: DateTime.parse(json['sentAt'] as String),
    message: SmsMessage(
      senderId: json['senderId'] as String?,
      to: json['to'] as String,
      route: SmsRoute.values.firstWhere(
        (route) => route.id == json['route'],
        orElse: () => SmsRoute.route5,
      ),
      type: SmsType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => SmsType.normal,
      ),
      text: json['text'] as String,
      forceIso88591: json['forceIso88591'] as bool? ?? false,
    ),
    success: json['success'] as bool,
    error: json['error'] as String?,
    result:
        json['balance'] == null &&
            json['cost'] == null &&
            json['messageId'] == null
        ? null
        : SmsResult(
            balance: json['balance'] as String?,
            cost: json['cost'] as String?,
            messageId: json['messageId'] as String?,
          ),
  );

  final String id;
  final DateTime sentAt;
  final SmsMessage message;
  final bool success;
  final String? error;
  final SmsResult? result;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'sentAt': sentAt.toIso8601String(),
    if (message.hasSenderId) 'senderId': message.senderId,
    'to': message.to,
    'route': message.route.id,
    'type': message.type.name,
    'text': message.text,
    'forceIso88591': message.forceIso88591,
    'success': success,
    if (error != null) 'error': error,
    if (result?.balance != null) 'balance': result!.balance,
    if (result?.cost != null) 'cost': result!.cost,
    if (result?.messageId != null) 'messageId': result!.messageId,
  };
}
