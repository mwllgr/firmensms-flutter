import 'dart:convert';

import 'package:firmensms/models/sms_message.dart';
import 'package:firmensms/models/sms_result.dart';
import 'package:firmensms/services/credentials_store.dart';
import 'package:firmensms/services/sms_api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeCredentialsStore extends CredentialsStore {
  const _FakeCredentialsStore(this._credentials)
    : super(const FlutterSecureStorage());

  final Credentials? _credentials;

  @override
  Future<Credentials?> read() async => _credentials;
}

const _message = SmsMessage(to: '00436641234567', text: 'Hallo');

SmsApiClient _client(
  Future<http.Response> Function(http.Request request) handler, {
  Credentials? credentials = (username: 'user', password: 'secret'),
}) {
  return SmsApiClient(
    client: MockClient(handler),
    credentials: _FakeCredentialsStore(credentials),
  );
}

void main() {
  test('sends a JSON POST with basic auth and no charset', () async {
    late http.Request captured;
    final client = _client((request) async {
      captured = request;
      return http.Response('{"error":"0"}', 200);
    });

    await client.send(_message);

    expect(captured.method, 'POST');
    expect(captured.url, SmsApiClient.endpoint);
    expect(captured.headers['Content-Type'], 'application/json');
    expect(captured.headers['User-Agent'], SmsApiClient.userAgent);
    expect(
      captured.headers['Authorization'],
      'Basic ${base64Encode(utf8.encode('user:secret'))}',
    );
    expect(jsonDecode(captured.body), _message.toJson());
  });

  test('parses balance, cost, and message id on success', () async {
    final client = _client(
      (_) async => http.Response(
        '{"error":"0","balance":"12.50","cost":0.075,"msgid":42}',
        200,
      ),
    );

    final result = await client.send(_message);

    expect(result.hasDetails, isTrue);
    expect(result.balance, '12.50');
    expect(result.cost, '0.075');
    expect(result.messageId, '42');
  });

  test('returns a result without details when they are missing', () async {
    final client = _client((_) async => http.Response('{"error":"0"}', 200));

    final result = await client.send(_message);

    expect(result.hasDetails, isFalse);
  });

  test('maps known error codes to German messages', () async {
    final client = _client((_) async => http.Response('{"error":"8"}', 200));

    expect(
      () => client.send(_message),
      throwsA(
        isA<SmsException>()
            .having((e) => e.code, 'code', '8')
            .having(
              (e) => e.message,
              'message',
              'F-8: Guthaben nicht ausreichend',
            ),
      ),
    );
  });

  test('reports unknown error codes', () async {
    final client = _client((_) async => http.Response('{"error":"99"}', 200));

    expect(
      () => client.send(_message),
      throwsA(
        isA<SmsException>().having(
          (e) => e.message,
          'message',
          'Unbekannter Fehler: 99',
        ),
      ),
    );
  });

  test('rejects responses that are not JSON or lack an error field', () async {
    for (final body in ['<html>', '{"status":"ok"}', '[]']) {
      final client = _client((_) async => http.Response(body, 200));
      expect(
        () => client.send(_message),
        throwsA(
          isA<SmsException>().having(
            (e) => e.message,
            'message',
            contains('unerwartete Antwort'),
          ),
        ),
        reason: body,
      );
    }
  });

  test('fails before sending when credentials are missing', () async {
    var requests = 0;
    final client = _client((_) async {
      requests++;
      return http.Response('{"error":"0"}', 200);
    }, credentials: null);

    await expectLater(
      client.send(_message),
      throwsA(
        isA<SmsException>().having(
          (e) => e.message,
          'message',
          contains('Einstellungen'),
        ),
      ),
    );
    expect(requests, 0);
  });
}
