import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_template.dart';
import 'preference_list.dart';

class TemplateStore {
  TemplateStore({SharedPreferencesAsync? preferences})
    : _list = PreferenceList<MessageTemplate>(
        preferences: preferences ?? SharedPreferencesAsync(),
        key: 'message_templates',
        fromJson: MessageTemplate.fromJson,
        toJson: (template) => template.toJson(),
      );

  final PreferenceList<MessageTemplate> _list;

  Future<List<MessageTemplate>> loadAll() => _list.load();

  Future<List<MessageTemplate>> upsert(MessageTemplate template) async {
    final templates = await _list.load();
    final index = templates.indexWhere((item) => item.id == template.id);
    if (index < 0) {
      templates.add(template);
    } else {
      templates[index] = template;
    }
    templates.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    await _list.save(templates);
    return templates;
  }

  Future<List<MessageTemplate>> delete(String id) async {
    final templates = (await _list.load())
        .where((item) => item.id != id)
        .toList();
    await _list.save(templates);
    return templates;
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
