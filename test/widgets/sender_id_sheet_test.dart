import 'package:firmensms/services/sender_id_store.dart';
import 'package:firmensms/widgets/sender_id_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SenderIdStore store;
  String? picked;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = SenderIdStore(preferences: SharedPreferencesAsync());
    picked = null;
    await store.save('Firma');
    await store.remember('0043664');
  });

  Future<void> open(WidgetTester tester, String current) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await showSenderIdSheet(
                  context,
                  store: store,
                  current: current,
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
  }

  testWidgets('shows saved entries, saves the current one and picks', (
    tester,
  ) async {
    await open(tester, 'Neu');

    expect(find.text('Firma'), findsOneWidget);
    expect(find.text('0043664'), findsNothing);

    await tester.tap(find.text('„Neu“ speichern'));
    await tester.pumpAndSettle();
    expect(await store.loadSaved(), ['Firma', 'Neu']);

    await tester.tap(find.text('Firma'));
    await tester.pumpAndSettle();
    expect(picked, 'Firma');
  });

  testWidgets('switches to history, clears it and picks from it', (
    tester,
  ) async {
    await open(tester, '');

    await tester.tap(find.text('Historie'));
    await tester.pumpAndSettle();
    expect(find.text('Absender-Historie'), findsOneWidget);
    expect(find.text('0043664'), findsOneWidget);

    await tester.tap(find.text('Leeren'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Leeren').last);
    await tester.pumpAndSettle();
    expect(await store.loadHistory(), isEmpty);
    expect(find.textContaining('Noch keine Einträge'), findsOneWidget);

    await store.remember('0043664');
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0043664'));
    await tester.pumpAndSettle();
    expect(picked, '0043664');
  });
}
