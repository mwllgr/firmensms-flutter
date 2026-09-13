import 'package:firmensms/models/send_plan.dart';
import 'package:firmensms/models/sms_message.dart';
import 'package:firmensms/services/credentials_store.dart';
import 'package:firmensms/services/history_store.dart';
import 'package:firmensms/services/message_sender.dart';
import 'package:firmensms/services/sender_id_store.dart';
import 'package:firmensms/services/sms_api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeCredentialsStore extends CredentialsStore {
  const _FakeCredentialsStore() : super(const FlutterSecureStorage());

  @override
  Future<Credentials?> read() async => (username: 'u', password: 'p');
}

void main() {
  late HistoryStore history;
  late SenderIdStore senderIds;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final preferences = SharedPreferencesAsync();
    history = HistoryStore(preferences: preferences);
    senderIds = SenderIdStore(preferences: preferences);
  });

  MessageSender sender(Future<http.Response> Function(http.Request) handler) =>
      MessageSender(
        client: SmsApiClient(
          client: MockClient(handler),
          credentials: const _FakeCredentialsStore(),
        ),
        historyStore: history,
        senderIdStore: senderIds,
      );

  test('SendPlan expands recipients times count', () {
    const plan = SendPlan(
      message: SmsMessage(to: '', text: 'x', senderId: 'Firma'),
      recipients: ['1', '2'],
      count: 3,
    );

    expect(plan.messagesPerRound, 6);
    expect(plan.messages.map((m) => m.to), ['1', '1', '1', '2', '2', '2']);
    expect(plan.messages.first.senderId, 'Firma');
    expect(plan.isAutomatic, isFalse);
  });

  test(
    'sendAll yields one outcome per message and records everything',
    () async {
      final requests = <String>[];
      final subject = sender((request) async {
        final to = (request.body.contains('"to":"2"')) ? '2' : '1';
        requests.add(to);
        return http.Response(
          to == '2' ? '{"error":"14"}' : '{"error":"0","cost":"0.075"}',
          200,
        );
      });
      const plan = SendPlan(
        message: SmsMessage(to: '', text: 'Hallo', senderId: 'Firma'),
        recipients: ['1', '2'],
        count: 2,
      );

      final outcomes = await subject.sendAll(plan.messages).toList();

      expect(requests, ['1', '1', '2', '2']);
      expect(outcomes.where((o) => o.success).length, 2);
      expect(outcomes.where((o) => !o.success).length, 2);
      expect(outcomes.last.error?.code, '14');
      final entries = await history.loadAll();
      expect(entries.length, 4);
      expect(entries.where((e) => e.success).length, 2);
      expect(await senderIds.loadAll(), ['Firma']);
    },
  );

  test(
    'sendRepeatedly keeps sending rounds until the listener cancels',
    () async {
      var requests = 0;
      final subject = sender((_) async {
        requests++;
        return http.Response('{"error":"0"}', 200);
      });

      final stream = subject.sendRepeatedly(const [
        SmsMessage(to: '1', text: 'x'),
      ], interval: const Duration(milliseconds: 20));
      final received = <bool>[];
      final subscription = stream.listen(
        (outcome) => received.add(outcome.success),
      );
      await Future<void>.delayed(const Duration(milliseconds: 130));
      await subscription.cancel();
      final countAtCancel = requests;
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(received.length, greaterThanOrEqualTo(3));
      expect(requests, countAtCancel);
    },
  );
}
