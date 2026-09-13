import 'package:shared_preferences/shared_preferences.dart';

class SenderIdStore {
  SenderIdStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _key = 'sender_ids';
  static const int maxEntries = 30;

  final SharedPreferencesAsync _preferences;

  Future<List<String>> loadAll() async =>
      await _preferences.getStringList(_key) ?? <String>[];

  Future<List<String>> remember(String senderId) async {
    final value = senderId.trim();
    if (value.isEmpty) {
      return loadAll();
    }
    final entries = await loadAll();
    entries.remove(value);
    entries.insert(0, value);
    if (entries.length > maxEntries) {
      entries.removeRange(maxEntries, entries.length);
    }
    await _preferences.setStringList(_key, entries);
    return entries;
  }

  Future<List<String>> forget(String senderId) async {
    final entries = await loadAll();
    entries.remove(senderId);
    await _preferences.setStringList(_key, entries);
    return entries;
  }
}
