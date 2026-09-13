import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';
import 'preference_list.dart';

class HistoryStore {
  HistoryStore({SharedPreferencesAsync? preferences})
    : _list = PreferenceList<HistoryEntry>(
        preferences: preferences ?? SharedPreferencesAsync(),
        key: 'message_history',
        fromJson: HistoryEntry.fromJson,
        toJson: (entry) => entry.toJson(),
      );

  static const int maxEntries = 200;

  final PreferenceList<HistoryEntry> _list;

  Future<List<HistoryEntry>> loadAll() => _list.load();

  Future<List<HistoryEntry>> add(HistoryEntry entry) async {
    final entries = await _list.load();
    entries.insert(0, entry);
    if (entries.length > maxEntries) {
      entries.removeRange(maxEntries, entries.length);
    }
    await _list.save(entries);
    return entries;
  }

  Future<List<HistoryEntry>> delete(String id) async {
    final entries = (await _list.load())
        .where((entry) => entry.id != id)
        .toList();
    await _list.save(entries);
    return entries;
  }

  Future<void> clear() => _list.save(const []);

  String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
