class SmsResult {
  const SmsResult({this.balance, this.cost, this.messageId});

  final String? balance;
  final String? cost;
  final String? messageId;

  bool get hasDetails => balance != null && cost != null && messageId != null;
}

class SmsException implements Exception {
  const SmsException(this.message, {this.code});

  static const Map<String, String> _messages = <String, String>{
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
    '17': 'Versand verhindert: Empfänger auf Opt-Out-Liste',
  };

  factory SmsException.fromCode(String code) {
    final description = _messages[code];
    return SmsException(
      description == null
          ? 'Unbekannter Fehler: $code'
          : 'F-$code: $description',
      code: code,
    );
  }

  const SmsException.missingCredentials()
    : this(
        'Legen Sie zuerst in den Einstellungen (rechts oben) Benutzername und Passwort fest.',
      );

  SmsException.unexpectedResponse(String body)
    : this('Vom Server wurde eine unerwartete Antwort empfangen:\n$body');

  final String message;
  final String? code;

  @override
  String toString() => message;
}
