import 'package:firmensms/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows the compose form', (tester) async {
    await tester.pumpWidget(const SmsApp(showOnboarding: false));

    expect(find.text('Firmensms'), findsOneWidget);
    expect(find.text('Absenderkennung'), findsOneWidget);
    expect(find.text('Empfänger'), findsOneWidget);
    expect(find.text('Nachricht'), findsOneWidget);
    expect(find.text('ISO-8859-1 erzwingen'), findsOneWidget);
  });

  testWidgets('validates required fields before confirming', (tester) async {
    await tester.pumpWidget(const SmsApp(showOnboarding: false));

    await tester.tap(find.widgetWithText(FilledButton, 'Senden'));
    await tester.pumpAndSettle();

    expect(find.text('Feld darf nicht leer sein'), findsNWidgets(2));
    expect(find.text('Wirklich senden?'), findsNothing);
  });

  testWidgets('asks for confirmation with the normalized recipient', (
    tester,
  ) async {
    await tester.pumpWidget(const SmsApp(showOnboarding: false));

    await tester.enterText(
      find.widgetWithText(TextField, 'Empfänger'),
      '0664 1234567',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nachricht'),
      'Hallo',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Senden'));
    await tester.pumpAndSettle();

    expect(find.text('Wirklich senden?'), findsOneWidget);
    expect(find.textContaining('Empfänger: 00436641234567'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
    await tester.pumpAndSettle();

    expect(find.text('Wirklich senden?'), findsNothing);
  });

  testWidgets('collects several recipients as chips and confirms the count', (
    tester,
  ) async {
    await tester.pumpWidget(const SmsApp(showOnboarding: false));

    await tester.enterText(
      find.widgetWithText(TextField, 'Empfänger'),
      '0664 1234567',
    );
    await tester.tap(find.byTooltip('Empfänger hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '00436641234567'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Weiterer Empfänger'),
      '+49 170 1234567',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nachricht'),
      'Hallo',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Senden'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Senden'));
    await tester.pumpAndSettle();

    expect(find.text('Wirklich senden?'), findsOneWidget);
    expect(find.textContaining('Empfänger (2):'), findsOneWidget);
    expect(find.textContaining('00491701234567'), findsOneWidget);
    expect(find.textContaining('SMS gesamt: 2'), findsOneWidget);
  });
}
