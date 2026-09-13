import 'sms_message.dart';
import 'sms_result.dart';

class SendOutcome {
  const SendOutcome.success(this.message, this.result) : error = null;

  const SendOutcome.failure(this.message, this.error) : result = null;

  final SmsMessage message;
  final SmsResult? result;
  final SmsException? error;

  bool get success => error == null;
}
