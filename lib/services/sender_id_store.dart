import 'package:shared_preferences/shared_preferences.dart';

class SenderIdStore {
  SenderIdStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _savedKey = 'sender_ids_saved';
  static const String _historyKey = 'sender_ids';
  static const int maxHistoryEntries = 30;

  final SharedPreferencesAsync _preferences;

  Future<List<String>> loadSaved() => _load(_savedKey);

  Future<List<String>> loadHistory() => _load(_historyKey);

  Future<List<String>> save(String senderId) async {
    final value = senderId.trim();
    final entries = await loadSaved();
    if (value.isEmpty || entries.contains(value)) {
      return entries;
    }
    entries.add(value);
    entries.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await _preferences.setStringList(_savedKey, entries);
    return entries;
  }

  Future<List<String>> unsave(String senderId) async {
    final entries = await loadSaved();
    entries.remove(senderId);
    await _preferences.setStringList(_savedKey, entries);
    return entries;
  }

  Future<List<String>> remember(String senderId) async {
    final value = senderId.trim();
    if (value.isEmpty) {
      return loadHistory();
    }
    final entries = await loadHistory();
    entries.remove(value);
    entries.insert(0, value);
    if (entries.length > maxHistoryEntries) {
      entries.removeRange(maxHistoryEntries, entries.length);
    }
    await _preferences.setStringList(_historyKey, entries);
    return entries;
  }

  Future<void> clearHistory() =>
      _preferences.setStringList(_historyKey, const []);

  Future<List<String>> _load(String key) async =>
      List<String>.of(await _preferences.getStringList(key) ?? const []);
}
