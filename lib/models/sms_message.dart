enum SmsType {
  normal('Normal'),
  voice('Voice'),
  flash('Flash');

  const SmsType(this.label);

  final String label;
}

enum SmsRoute {
  route3('3', 'EUR 0,085'),
  route5('5', 'EUR 0,075'),
  route6('6', 'EUR 0,05');

  const SmsRoute(this.id, this.price);

  final String id;
  final String price;

  String get label => '$id ($price)';
}

class SmsMessage {
  const SmsMessage({
    required this.to,
    required this.text,
    this.senderId,
    this.route = SmsRoute.route5,
    this.type = SmsType.normal,
    this.forceIso88591 = false,
  });

  final String? senderId;
  final String to;
  final SmsRoute route;
  final SmsType type;
  final String text;
  final bool forceIso88591;

  bool get hasSenderId => senderId != null && senderId!.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (hasSenderId) 'senderid': senderId,
    'to': to,
    'route': route.id,
    if (type != SmsType.normal) 'type': type.name,
    'text': text,
    'encoding': forceIso88591 ? 'ISO-8859-1' : 'auto',
  };
}
