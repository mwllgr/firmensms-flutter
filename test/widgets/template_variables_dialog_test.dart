import 'package:firmensms/widgets/template_variables_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('collects a value per variable and requires all of them', (
    tester,
  ) async {
    Map<String, String>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showTemplateVariablesDialog(
                  context,
                  variables: const ['name', 'zeit'],
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

    await tester.tap(find.text('Einfügen'));
    await tester.pumpAndSettle();
    expect(find.text('Feld darf nicht leer sein'), findsNWidgets(2));

    await tester.enterText(find.widgetWithText(TextFormField, 'name'), 'Anna');
    await tester.enterText(find.widgetWithText(TextFormField, 'zeit'), '14:30');
    await tester.tap(find.text('Einfügen'));
    await tester.pumpAndSettle();

    expect(result, {'name': 'Anna', 'zeit': '14:30'});
  });
}
