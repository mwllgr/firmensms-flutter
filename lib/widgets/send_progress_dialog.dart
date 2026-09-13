import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/send_outcome.dart';

Future<void> showSendProgressDialog(
  BuildContext context, {
  required Stream<SendOutcome> outcomes,
  required int? total,
  Duration? interval,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SendProgressDialog(
      outcomes: outcomes,
      total: total,
      interval: interval,
    ),
  );
}

class SendProgressDialog extends StatefulWidget {
  const SendProgressDialog({
    super.key,
    required this.outcomes,
    required this.total,
    this.interval,
  });

  final Stream<SendOutcome> outcomes;
  final int? total;
  final Duration? interval;

  bool get unbounded => total == null;

  @override
  State<SendProgressDialog> createState() => _SendProgressDialogState();
}

class _SendProgressDialogState extends State<SendProgressDialog> {
  final List<SendOutcome> _results = [];
  late final StreamSubscription<SendOutcome> _subscription;
  bool _done = false;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.outcomes.listen(
      (outcome) => setState(() => _results.add(outcome)),
      onDone: () => setState(() => _done = true),
      onError: (Object error) => setState(() => _done = true),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _stop() {
    _subscription.cancel();
    setState(() {
      _stopped = true;
      _done = true;
    });
  }

  int get _succeeded => _results.where((outcome) => outcome.success).length;

  int get _failed => _results.length - _succeeded;

  bool get _singleShot => widget.total == 1;

  String get _status {
    if (_singleShot) {
      if (_results.isEmpty) {
        return _stopped ? 'Abgebrochen' : 'Wird gesendet...';
      }
      final outcome = _results.single;
      if (!outcome.success) {
        return outcome.error!.message;
      }
      final result = outcome.result;
      if (result == null || !result.hasDetails) {
        return 'SMS gesendet!';
      }
      return 'SMS gesendet!\n\n'
          'Guthaben: ${result.balance}\n'
          'Kosten: ${result.cost}\n\n'
          'ID: ${result.messageId}';
    }
    final counts = '$_succeeded gesendet, $_failed fehlgeschlagen';
    if (widget.unbounded) {
      final seconds = widget.interval?.inSeconds;
      final cadence = seconds == null ? '' : ' alle $seconds Sekunden';
      return _stopped
          ? 'Gestoppt nach ${_results.length} SMS: $counts'
          : 'Automatischer Versand$cadence läuft.\n${_results.length} SMS bisher: $counts';
    }
    final progress = '${_results.length} von ${widget.total}';
    if (_stopped) {
      return 'Abgebrochen nach $progress: $counts';
    }
    return _done ? 'Fertig: $counts' : '$progress verarbeitet: $counts';
  }

  @override
  Widget build(BuildContext context) {
    final running = !_done;
    final total = widget.total;
    final recent = _results.length > 20
        ? _results.sublist(_results.length - 20)
        : _results;
    return PopScope(
      canPop: _done,
      child: AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.unbounded && running ? Icons.autorenew : Icons.message,
                size: 70,
                color: Colors.orange,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  widget.unbounded ? 'Automatischer Versand' : 'SMS-Versand',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: LinearProgressIndicator(
                  value: total == null
                      ? (running ? null : 1)
                      : (total == 0 ? 1 : _results.length / total),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(_status),
                ),
              ),
              if (!_singleShot)
                for (final outcome in recent)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      outcome.success
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: outcome.success ? Colors.green : Colors.redAccent,
                    ),
                    title: Text(outcome.message.to),
                    subtitle: outcome.success
                        ? (outcome.result?.cost == null
                              ? null
                              : Text('Kosten: ${outcome.result!.cost}'))
                        : Text(outcome.error!.message),
                  ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 5),
        actions: [
          if (running && !_singleShot)
            TextButton(
              onPressed: _stop,
              child: Text(widget.unbounded ? 'Stoppen' : 'Abbrechen'),
            ),
          TextButton(
            onPressed: running ? null : () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
