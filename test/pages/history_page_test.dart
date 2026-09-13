import 'package:firmensms/models/history_entry.dart';
import 'package:firmensms/models/sms_message.dart';
import 'package:firmensms/pages/history_page.dart';
import 'package:firmensms/services/history_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late HistoryStore store;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = HistoryStore(preferences: SharedPreferencesAsync());
    await store.add(
      HistoryEntry(
        id: '1',
        sentAt: DateTime(2026, 9, 13, 8, 5),
        message: const SmsMessage(to: '00436641234567', text: 'Hallo Anna'),
        success: true,
      ),
    );
    await store.add(
      HistoryEntry(
        id: '2',
        sentAt: DateTime(2026, 9, 13, 8, 6),
        message: const SmsMessage(to: '00436649999999', text: 'Fehlversuch'),
        success: false,
        error: 'F-8: Guthaben nicht ausreichend',
      ),
    );
  });

  Future<SmsMessage?> open(WidgetTester tester) async {
    SmsMessage? reused;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                reused = await Navigator.of(context).push<SmsMessage>(
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(store: store),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return reused;
  }

  testWidgets('lists entries newest first and deletes one', (tester) async {
    await open(tester);

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles[0].title as Text).data, '00436649999999');
    expect((tiles[1].title as Text).data, '00436641234567');

    await tester.tap(find.byTooltip('Löschen').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
    await tester.pumpAndSettle();

    expect(find.text('00436649999999'), findsNothing);
    expect((await store.loadAll()).map((e) => e.id), ['1']);
  });

  testWidgets('clears the whole history', (tester) async {
    await open(tester);

    await tester.tap(find.byTooltip('Verlauf löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine gesendeten Nachrichten.'), findsOneWidget);
    expect(await store.loadAll(), isEmpty);
  });

  testWidgets('shows details and returns the message for reuse', (
    tester,
  ) async {
    SmsMessage? reused;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                reused = await Navigator.of(context).push<SmsMessage>(
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(store: store),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('00436641234567'));
    await tester.pumpAndSettle();
    expect(find.text('Hallo Anna'), findsWidgets);
    expect(find.textContaining('Status: gesendet'), findsOneWidget);

    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(reused?.to, '00436641234567');
    expect(reused?.text, 'Hallo Anna');
  });
}
