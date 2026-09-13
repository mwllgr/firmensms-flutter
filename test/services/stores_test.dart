import 'package:firmensms/models/history_entry.dart';
import 'package:firmensms/models/message_template.dart';
import 'package:firmensms/models/sms_message.dart';
import 'package:firmensms/models/sms_result.dart';
import 'package:firmensms/services/history_store.dart';
import 'package:firmensms/services/sender_id_store.dart';
import 'package:firmensms/services/template_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesAsync preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
  });

  group('TemplateStore', () {
    test('upserts sorted by name and deletes by id', () async {
      final store = TemplateStore(preferences: preferences);

      await store.upsert(
        const MessageTemplate(id: 'b', name: 'Zeta', text: 'z'),
      );
      await store.upsert(
        const MessageTemplate(
          id: 'a',
          name: 'Alpha',
          text: '{name}',
          senderId: 'Firma',
        ),
      );
      await store.upsert(
        const MessageTemplate(id: 'b', name: 'Beta', text: 'b'),
      );

      final templates = await store.loadAll();
      expect(templates.map((t) => t.name), ['Alpha', 'Beta']);
      expect(templates.first.senderId, 'Firma');
      expect(templates.first.variables, ['name']);

      await store.delete('a');
      expect((await store.loadAll()).map((t) => t.id), ['b']);
    });
  });

  group('SenderIdStore', () {
    test(
      'history keeps most recent first without duplicates and can be cleared',
      () async {
        final store = SenderIdStore(preferences: preferences);

        await store.remember('Firma');
        await store.remember('0043664');
        await store.remember('Firma');
        await store.remember('   ');

        expect(await store.loadHistory(), ['Firma', '0043664']);
        expect(await store.loadSaved(), isEmpty);

        await store.clearHistory();
        expect(await store.loadHistory(), isEmpty);
      },
    );

    test('saved entries are sorted, unique and removable', () async {
      final store = SenderIdStore(preferences: preferences);

      await store.save('Zeta');
      await store.save('alpha');
      await store.save('Zeta');
      await store.save('');

      expect(await store.loadSaved(), ['alpha', 'Zeta']);

      await store.unsave('Zeta');
      expect(await store.loadSaved(), ['alpha']);
      expect(await store.loadHistory(), isEmpty);
    });
  });

  group('HistoryStore', () {
    test(
      'adds newest first, round-trips all fields, deletes and clears',
      () async {
        final store = HistoryStore(preferences: preferences);
        const message = SmsMessage(
          senderId: 'Firma',
          to: '00436641234567',
          route: SmsRoute.route3,
          type: SmsType.flash,
          text: 'Hallo',
          forceIso88591: true,
        );

        await store.add(
          HistoryEntry(
            id: '1',
            sentAt: DateTime(2026, 9, 13, 8, 5),
            message: message,
            success: false,
            error: 'F-8: Guthaben nicht ausreichend',
          ),
        );
        await store.add(
          HistoryEntry(
            id: '2',
            sentAt: DateTime(2026, 9, 13, 8, 6),
            message: message,
            success: true,
            result: const SmsResult(
              balance: '1.00',
              cost: '0.085',
              messageId: '42',
            ),
          ),
        );

        final entries = await store.loadAll();
        expect(entries.map((e) => e.id), ['2', '1']);
        final latest = entries.first;
        expect(latest.success, isTrue);
        expect(latest.result?.messageId, '42');
        expect(latest.message.senderId, 'Firma');
        expect(latest.message.route, SmsRoute.route3);
        expect(latest.message.type, SmsType.flash);
        expect(latest.message.forceIso88591, isTrue);
        expect(entries.last.error, 'F-8: Guthaben nicht ausreichend');
        expect(entries.last.result, isNull);

        await store.delete('2');
        expect((await store.loadAll()).map((e) => e.id), ['1']);

        await store.clear();
        expect(await store.loadAll(), isEmpty);
      },
    );
  });
}
