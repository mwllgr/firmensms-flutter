import 'package:material_ui/material_ui.dart';

import '../models/history_entry.dart';
import '../services/history_store.dart';
import '../utils/date_format.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.store});

  final HistoryStore? store;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final HistoryStore _store = widget.store ?? HistoryStore();
  late Future<List<HistoryEntry>> _entries = _store.loadAll();

  Future<bool> _confirm(String title, String text) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(HistoryEntry entry) async {
    if (await _confirm(
      'Eintrag löschen?',
      'Soll dieser Eintrag aus dem Verlauf gelöscht werden?',
    )) {
      setState(() {
        _entries = _store.delete(entry.id);
      });
    }
  }

  Future<void> _clear() async {
    if (await _confirm(
      'Verlauf löschen?',
      'Soll der gesamte Verlauf gelöscht werden?',
    )) {
      await _store.clear();
      setState(() {
        _entries = _store.loadAll();
      });
    }
  }

  Future<void> _showDetails(HistoryEntry entry) async {
    final reuse = await showDialog<bool>(
      context: context,
      builder: (context) => _HistoryDetailDialog(entry: entry),
    );
    if (reuse == true && mounted) {
      Navigator.of(context).pop(entry.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verlauf'),
        actions: [
          FutureBuilder<List<HistoryEntry>>(
            future: _entries,
            builder: (context, snapshot) => IconButton(
              onPressed: (snapshot.data?.isEmpty ?? true) ? null : _clear,
              tooltip: 'Verlauf löschen',
              icon: const Icon(
                Icons.delete_sweep_outlined,
                semanticLabel: 'Verlauf löschen',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<HistoryEntry>>(
          future: _entries,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snapshot.data ?? const <HistoryEntry>[];
            if (entries.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'Noch keine gesendeten Nachrichten.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Dismissible(
                  key: ValueKey(entry.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirm(
                    'Eintrag löschen?',
                    'Soll dieser Eintrag aus dem Verlauf gelöscht werden?',
                  ),
                  onDismissed: (_) => setState(() {
                    _entries = _store.delete(entry.id);
                  }),
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Icon(
                      entry.success
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: entry.success ? Colors.green : Colors.redAccent,
                    ),
                    title: Text(entry.message.to),
                    subtitle: Text(
                      '${formatDateTime(entry.sentAt)}\n${entry.message.text}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    onTap: () => _showDetails(entry),
                    trailing: IconButton(
                      tooltip: 'Löschen',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(entry),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistoryDetailDialog extends StatelessWidget {
  const _HistoryDetailDialog({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final message = entry.message;
    final result = entry.result;
    final lines = <String>[
      'Zeitpunkt: ${formatDateTime(entry.sentAt)}',
      if (message.hasSenderId) 'Absender: ${message.senderId}',
      'Empfänger: ${message.to}',
      'Route: ${message.route.label}',
      'Typ: ${message.type.label}',
      if (message.forceIso88591) 'Kodierung: ISO-8859-1',
      '',
      entry.success ? 'Status: gesendet' : 'Status: fehlgeschlagen',
      if (entry.error != null) entry.error!,
      if (result?.cost != null) 'Kosten: ${result!.cost}',
      if (result?.balance != null) 'Guthaben: ${result!.balance}',
      if (result?.messageId != null) 'ID: ${result!.messageId}',
    ];
    return AlertDialog(
      title: const Text('Nachricht'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(message.text),
            const Divider(height: 24),
            SelectableText(lines.join('\n')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Schließen'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Erneut verwenden'),
        ),
      ],
    );
  }
}
