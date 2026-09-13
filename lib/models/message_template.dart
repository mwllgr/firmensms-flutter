import '../utils/template_variables.dart';

class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.name,
    required this.text,
    this.senderId,
  });

  factory MessageTemplate.fromJson(Map<String, dynamic> json) =>
      MessageTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        text: json['text'] as String,
        senderId: json['senderId'] as String?,
      );

  final String id;
  final String name;
  final String text;
  final String? senderId;

  List<String> get variables => extractCustomPlaceholders(text);

  bool get hasSenderId => senderId != null && senderId!.isNotEmpty;

  MessageTemplate copyWith({String? name, String? text, String? senderId}) =>
      MessageTemplate(
        id: id,
        name: name ?? this.name,
        text: text ?? this.text,
        senderId: senderId ?? this.senderId,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'text': text,
    if (hasSenderId) 'senderId': senderId,
  };
}
