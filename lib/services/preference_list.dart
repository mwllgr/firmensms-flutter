import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PreferenceList<T> {
  const PreferenceList({
    required this.preferences,
    required this.key,
    required this.fromJson,
    required this.toJson,
  });

  final SharedPreferencesAsync preferences;
  final String key;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;

  Future<List<T>> load() async {
    final raw = await preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return <T>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <T>[];
    }
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) fromJson(item),
    ];
  }

  Future<void> save(List<T> items) => preferences.setString(
    key,
    jsonEncode([for (final item in items) toJson(item)]),
  );
}
