import '../models/history_entry.dart';
import '../models/send_outcome.dart';
import '../models/sms_message.dart';
import '../models/sms_result.dart';
import 'history_store.dart';
import 'sender_id_store.dart';
import 'sms_api_client.dart';

class MessageSender {
  MessageSender({
    SmsApiClient? client,
    HistoryStore? historyStore,
    SenderIdStore? senderIdStore,
  }) : _client = client ?? SmsApiClient(),
       _history = historyStore ?? HistoryStore(),
       _senderIds = senderIdStore ?? SenderIdStore();

  final SmsApiClient _client;
  final HistoryStore _history;
  final SenderIdStore _senderIds;

  Future<SendOutcome> send(SmsMessage message) async {
    final id = _history.newId();
    final sentAt = DateTime.now();
    try {
      final result = await _client.send(message);
      await _history.add(
        HistoryEntry(
          id: id,
          sentAt: sentAt,
          message: message,
          success: true,
          result: result,
        ),
      );
      if (message.hasSenderId) {
        await _senderIds.remember(message.senderId!);
      }
      return SendOutcome.success(message, result);
    } on SmsException catch (error) {
      await _history.add(
        HistoryEntry(
          id: id,
          sentAt: sentAt,
          message: message,
          success: false,
          error: error.message,
        ),
      );
      return SendOutcome.failure(message, error);
    }
  }

  Stream<SendOutcome> sendAll(List<SmsMessage> messages) async* {
    for (final message in messages) {
      yield await send(message);
    }
  }

  Stream<SendOutcome> sendRepeatedly(
    List<SmsMessage> messages, {
    required Duration interval,
  }) async* {
    while (true) {
      yield* sendAll(messages);
      await Future<void>.delayed(interval);
    }
  }
}
