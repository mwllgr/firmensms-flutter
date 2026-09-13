import 'package:firmensms/utils/template_variables.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 13, 8, 5);

  test('extracts placeholders in order without duplicates', () {
    expect(
      extractPlaceholders(
        'Hallo {name}, Termin am {datum} um {uhrzeit}. Bis dann, {name}!',
      ),
      ['name', 'datum', 'uhrzeit'],
    );
  });

  test('custom placeholders exclude built-in variables', () {
    expect(extractCustomPlaceholders('{name} {datum} { firma }'), [
      'name',
      'firma',
    ]);
  });

  test('renders values and built-in date and time', () {
    expect(
      renderTemplate('Hallo {name}, {datum} {uhrzeit}', {'name': 'Anna'}, now),
      'Hallo Anna, 13.09.2026 08:05',
    );
  });

  test('leaves unknown placeholders untouched', () {
    expect(renderTemplate('{unbekannt}', {}, now), '{unbekannt}');
  });
}
