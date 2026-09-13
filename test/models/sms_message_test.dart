import 'package:firmensms/models/sms_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes a minimal message with defaults', () {
    const message = SmsMessage(to: '00436641234567', text: 'Hallo');

    expect(message.toJson(), {
      'to': '00436641234567',
      'route': '5',
      'text': 'Hallo',
      'encoding': 'auto',
    });
  });

  test('includes sender id, type, and forced encoding when set', () {
    const message = SmsMessage(
      senderId: 'Firma',
      to: '00436641234567',
      route: SmsRoute.route3,
      type: SmsType.flash,
      text: 'Hallo',
      forceIso88591: true,
    );

    expect(message.toJson(), {
      'senderid': 'Firma',
      'to': '00436641234567',
      'route': '3',
      'type': 'flash',
      'text': 'Hallo',
      'encoding': 'ISO-8859-1',
    });
  });

  test('omits an empty sender id', () {
    const message = SmsMessage(senderId: '', to: '1', text: 'x');

    expect(message.hasSenderId, isFalse);
    expect(message.toJson().containsKey('senderid'), isFalse);
  });

  test('exposes route labels with prices', () {
    expect(SmsRoute.route5.label, '5 (EUR 0,075)');
    expect(SmsType.voice.label, 'Voice');
  });
}
