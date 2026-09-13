import 'date_format.dart';

final RegExp _placeholder = RegExp(r'\{([^{}]+)\}');

const Set<String> builtInVariables = <String>{'datum', 'uhrzeit'};

List<String> extractPlaceholders(String text) {
  final names = <String>[];
  for (final match in _placeholder.allMatches(text)) {
    final name = match.group(1)!.trim();
    if (name.isNotEmpty && !names.contains(name)) {
      names.add(name);
    }
  }
  return names;
}

List<String> extractCustomPlaceholders(String text) =>
    extractPlaceholders(text)
        .where((name) => !builtInVariables.contains(name))
        .toList();

Map<String, String> builtInValues([DateTime? now]) {
  final stamp = formatDateTime(now ?? DateTime.now());
  final parts = stamp.split(' ');
  return <String, String>{'datum': parts[0], 'uhrzeit': parts[1]};
}

String renderTemplate(
  String text,
  Map<String, String> values, [
  DateTime? now,
]) {
  final all = <String, String>{...builtInValues(now), ...values};
  return text.replaceAllMapped(_placeholder, (match) {
    final name = match.group(1)!.trim();
    return all[name] ?? match.group(0)!;
  });
}
