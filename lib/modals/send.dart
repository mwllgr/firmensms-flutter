import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class SendModal extends StatelessWidget {
  const SendModal({Key? key, required this.json}) : super(key: key);
  final String json;
  final _storage = const FlutterSecureStorage();

  static const int NO_AUTH = 1;
  static const Map<String, String> ERRORS = {
    '1': 'Ungültige Benutzerauthentifizierung',
    '2': 'Ungültige Benutzerauthentifizierung',
    '3': 'Fehlender Nachrichtentext',
    '4': 'Fehlende Empfängernummer',
    '5': 'Fehlende Absenderkennung',
    '7': 'Ungültiges Passwort',
    '8': 'Guthaben nicht ausreichend',
    '9': 'SMS konnte nicht angenommen/gesendet werden',
    '10': 'Absenderkennung ungültig',
    '11': 'SMS wurde als Spam erkannt. Im Webinterface kann die Erkennung deaktiviert werden.',
    '12': 'SMS wurde innerhalb der SMS-Pause eingeliefert',
    '13': 'SMS konnte nicht versendet werden',
    '14': 'Ungültige Empfängernummer',
    '15': 'Versand durch IP-Sperre verhindert',
    '16': '"data"-Parameter fehlt (XML)',
    '17': 'Versand verhindert: Empfänger auf Opt-Out-Liste'
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
          child: FutureBuilder<dynamic>(
        future: sendSms(),
        builder: (context, snapshot) {
          return Column(children: [
            const Icon(
              Icons.message,
              size: 70,
              color: Colors.orange,
            ),
            const Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Text('SMS-Versand',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
            Padding(
                padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                child: Row(children: [
                  if (!snapshot.hasData &&
                      snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(9, 0, 0, 0),
                          child: SelectableText(snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? "Wird geladen..."
                              : snapshot.hasData
                                  ? "SMS gesendet!" + snapshot.data
                                  : snapshot.error.toString())))
                ]))
          ]);
        },
      )),
      actionsPadding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
      actions: [
        TextButton(
          child: const Text('OK', style: TextStyle(color: Colors.orange)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  Future<String> sendSms() async {
    if (await _storage.containsKey(key: "username") &&
        await _storage.containsKey(key: "password")) {
      final user = await _storage.read(key: "username");
      final pass = await _storage.read(key: "password");
      final auth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

      if (kDebugMode) {
        print("Sending: $json");
      }

      // We have to use the manual way of creating a POST request
      // because 'http' adds "; charset=..." which doesn't work
      // with the firmensms.at REST API
      Request request = Request(
          'POST', Uri.parse("https://www.firmensms.at/gateway/rest/sms"));
      request.body = json;
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': auth,
        'User-Agent': 'at.mwllgr.firmensms'
      });
      final streamedResponse = await request.send();
      final response = await Response.fromStream(streamedResponse);

      var text = response.body;
      var body = jsonDecode(text) as Map<String, dynamic>;

      if (kDebugMode) {
        print("Received: $text");
      }

      if (body.containsKey("error")) {
        if (body["error"] == "0") {
          if (body.containsKey("balance") &&
              body.containsKey("cost") &&
              body.containsKey("msgid")) {
            final balance = body["balance"];
            final cost = body["cost"];
            final id = body["msgid"];

            return "\n\nGuthaben: $balance\nKosten: $cost\n\nID: $id";
          }

          return "";
        }

        return Future.error(ERRORS.containsKey(body["error"])
            ? "${"F-" + body["error"]}: ${ERRORS[body["error"]]!}"
            : "Unbekannter Fehler: " + body["error"]);
      } else {
        return Future.error(
            "Vom Server wurde eine unerwartete Antwort empfangen:\n$text");
      }
    } else {
      return Future.error(
          "Legen Sie zuerst in den Einstellungen (rechts oben) Benutzername und Passwort fest.");
    }
  }
}
