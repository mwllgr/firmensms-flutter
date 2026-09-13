import 'sms_message.dart';

class SendPlan {
  const SendPlan({
    required this.message,
    required this.recipients,
    this.count = 1,
    this.interval,
  });

  final SmsMessage message;
  final List<String> recipients;
  final int count;
  final Duration? interval;

  bool get isAutomatic => interval != null;

  int get messagesPerRound => recipients.length * count;

  List<SmsMessage> get messages => [
    for (final recipient in recipients)
      for (var i = 0; i < count; i++) message.copyWith(to: recipient),
  ];
}
