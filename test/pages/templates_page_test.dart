import 'package:firmensms/models/message_template.dart';
import 'package:firmensms/pages/templates_page.dart';
import 'package:firmensms/services/template_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late TemplateStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = TemplateStore(preferences: SharedPreferencesAsync());
  });

  Future<MessageTemplate?> pumpAndPick(
    WidgetTester tester, {
    String initialText = '',
  }) async {
    MessageTemplate? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await Navigator.of(context).push<MessageTemplate>(
                  MaterialPageRoute(
                    builder: (context) =>
                        TemplatesPage(store: store, initialText: initialText),
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
    return picked;
  }

  testWidgets('creates a template from the current text and lists it', (
    tester,
  ) async {
    await pumpAndPick(tester, initialText: 'Hallo {name}');
    expect(
      find.text('Noch keine Vorlagen vorhanden.', findRichText: true),
      findsNothing,
    );
    expect(find.textContaining('Noch keine Vorlagen'), findsOneWidget);

    await tester.tap(find.text('Neue Vorlage'));
    await tester.pumpAndSettle();

    expect(find.text('Neue Vorlage'), findsOneWidget);
    expect(find.text('Hallo {name}'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'name'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Gruß');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Gruß'), findsOneWidget);
    final saved = await store.loadAll();
    expect(saved.single.text, 'Hallo {name}');
  });

  testWidgets('returns the tapped template and deletes via menu', (
    tester,
  ) async {
    await store.upsert(const MessageTemplate(id: '1', name: 'Eins', text: 'a'));
    await store.upsert(const MessageTemplate(id: '2', name: 'Zwei', text: 'b'));

    MessageTemplate? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await Navigator.of(context).push<MessageTemplate>(
                  MaterialPageRoute(
                    builder: (context) => TemplatesPage(store: store),
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

    await tester.tap(find.byTooltip('Optionen').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Eins'), findsNothing);
    expect((await store.loadAll()).map((t) => t.id), ['2']);

    await tester.tap(find.widgetWithText(ListTile, 'Zwei'));
    await tester.pumpAndSettle();
    expect(picked?.id, '2');
  });
}
