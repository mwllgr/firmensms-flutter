import 'dart:async';

import 'package:firmensms/models/send_outcome.dart';
import 'package:firmensms/models/sms_message.dart';
import 'package:firmensms/models/sms_result.dart';
import 'package:firmensms/widgets/send_progress_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows progress, counts, and enables OK when done', (
    tester,
  ) async {
    final controller = StreamController<SendOutcome>();
    await tester.pumpWidget(
      MaterialApp(
        home: SendProgressDialog(outcomes: controller.stream, total: 3),
      ),
    );

    expect(
      find.text('0 von 3 verarbeitet: 0 gesendet, 0 fehlgeschlagen'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'OK'))
          .onPressed,
      isNull,
    );

    controller.add(
      const SendOutcome.success(
        SmsMessage(to: '1', text: 'x'),
        SmsResult(cost: '0.05'),
      ),
    );
    controller.add(
      const SendOutcome.failure(
        SmsMessage(to: '2', text: 'x'),
        SmsException('F-14: Ungültige Empfängernummer', code: '14'),
      ),
    );
    await tester.pump();

    expect(
      find.text('2 von 3 verarbeitet: 1 gesendet, 1 fehlgeschlagen'),
      findsOneWidget,
    );
    expect(find.text('F-14: Ungültige Empfängernummer'), findsOneWidget);

    controller.add(
      const SendOutcome.success(SmsMessage(to: '3', text: 'x'), SmsResult()),
    );
    await controller.close();
    await tester.pump();

    expect(find.text('Fertig: 2 gesendet, 1 fehlgeschlagen'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'OK'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('stop cancels an unbounded automatic run', (tester) async {
    var cancelled = false;
    final controller = StreamController<SendOutcome>(
      onCancel: () => cancelled = true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SendProgressDialog(
          outcomes: controller.stream,
          total: null,
          interval: const Duration(seconds: 30),
        ),
      ),
    );
    controller.add(
      const SendOutcome.success(SmsMessage(to: '1', text: 'x'), SmsResult()),
    );
    await tester.pump();

    expect(find.textContaining('alle 30 Sekunden'), findsOneWidget);

    await tester.tap(find.text('Stoppen'));
    await tester.pump();

    expect(cancelled, isTrue);
    expect(
      find.text('Gestoppt nach 1 SMS: 1 gesendet, 0 fehlgeschlagen'),
      findsOneWidget,
    );
  });
}
