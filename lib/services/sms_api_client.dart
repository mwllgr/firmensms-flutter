import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sms_message.dart';
import '../models/sms_result.dart';
import 'credentials_store.dart';

class SmsApiClient {
  SmsApiClient({http.Client? client, CredentialsStore? credentials})
    : _client = client ?? http.Client(),
      _credentials = credentials ?? const CredentialsStore();

  static final Uri endpoint = Uri.parse(
    'https://www.firmensms.at/gateway/rest/sms',
  );
  static const String userAgent = 'at.mwllgr.firmensms';

  final http.Client _client;
  final CredentialsStore _credentials;

  Future<SmsResult> send(SmsMessage message) async {
    final credentials = await _credentials.read();
    if (credentials == null) {
      throw const SmsException.missingCredentials();
    }

    final token = base64Encode(
      utf8.encode('${credentials.username}:${credentials.password}'),
    );
    final request = http.Request('POST', endpoint)
      ..body = jsonEncode(message.toJson())
      ..headers.addAll(<String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Basic $token',
        'User-Agent': userAgent,
      });

    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    return _parse(response.body);
  }

  SmsResult _parse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw SmsException.unexpectedResponse(body);
    }
    if (decoded is! Map<String, dynamic> || !decoded.containsKey('error')) {
      throw SmsException.unexpectedResponse(body);
    }

    final code = decoded['error'].toString();
    if (code != '0') {
      throw SmsException.fromCode(code);
    }
    return SmsResult(
      balance: decoded['balance']?.toString(),
      cost: decoded['cost']?.toString(),
      messageId: decoded['msgid']?.toString(),
    );
  }
}
