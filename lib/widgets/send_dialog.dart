import 'package:material_ui/material_ui.dart';

import '../models/sms_result.dart';

class SendDialog extends StatelessWidget {
  const SendDialog({super.key, required this.result});

  final Future<SmsResult> result;

  String _describe(AsyncSnapshot<SmsResult> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return 'Wird geladen...';
    }
    if (snapshot.hasError) {
      return snapshot.error.toString();
    }
    final result = snapshot.data;
    if (result == null || !result.hasDetails) {
      return 'SMS gesendet!';
    }
    return 'SMS gesendet!\n\n'
        'Guthaben: ${result.balance}\n'
        'Kosten: ${result.cost}\n\n'
        'ID: ${result.messageId}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: FutureBuilder<SmsResult>(
          future: result,
          builder: (context, snapshot) {
            final waiting = snapshot.connectionState == ConnectionState.waiting;
            return Column(
              children: [
                const Icon(Icons.message, size: 70, color: Colors.orange),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'SMS-Versand',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    children: [
                      if (waiting)
                        const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 9),
                          child: SelectableText(_describe(snapshot)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 5),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK', style: TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }
}
