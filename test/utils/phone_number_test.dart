import 'package:firmensms/utils/phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeRecipient', () {
    test('converts a leading plus to 00', () {
      expect(normalizeRecipient('+43 664 1234567'), '00436641234567');
      expect(normalizeRecipient('+436641234567'), '00436641234567');
    });

    test('expands a national number to the Austrian prefix', () {
      expect(normalizeRecipient('0664 1234567'), '00436641234567');
      expect(normalizeRecipient('0664/123-4567'), '00436641234567');
    });

    test('keeps an international number with 00 prefix', () {
      expect(normalizeRecipient('0049 170 1234567'), '00491701234567');
    });

    test('strips surrounding whitespace and non-digits', () {
      expect(normalizeRecipient('  +43 (664) 123 45 67 '), '00436641234567');
    });
  });

  group('normalizeSenderId', () {
    test('returns null for missing or empty input', () {
      expect(normalizeSenderId(null), isNull);
      expect(normalizeSenderId(''), isNull);
      expect(normalizeSenderId('   '), isNull);
    });

    test('converts a leading plus to 00 and strips non-digits', () {
      expect(normalizeSenderId('+43 664 1234567'), '00436641234567');
    });

    test('expands a national number to the Austrian prefix', () {
      expect(normalizeSenderId('0664 1234567'), '00436641234567');
    });

    test('keeps an international number with 00 prefix', () {
      expect(normalizeSenderId('00436641234567'), '00436641234567');
    });

    test('keeps alphanumeric sender ids untouched', () {
      expect(normalizeSenderId('Firma GmbH'), 'Firma GmbH');
      expect(normalizeSenderId('0800 Hotline'), '0800 Hotline');
    });
  });

  group('parseRecipients', () {
    test('splits on commas, semicolons and newlines and normalizes', () {
      expect(
        parseRecipients('+43 664 1234567, 0664 7654321;\n00491701234567'),
        ['00436641234567', '00436647654321', '00491701234567'],
      );
    });

    test('drops empty parts and duplicates', () {
      expect(parseRecipients(' , 0664 1234567,,+436641234567 '), [
        '00436641234567',
      ]);
      expect(parseRecipients(''), isEmpty);
    });
  });
}
