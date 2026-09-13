import 'package:material_ui/material_ui.dart';

import '../services/sender_id_store.dart';

Future<String?> showSenderIdSheet(
  BuildContext context, {
  required SenderIdStore store,
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SenderIdSheet(store: store, current: current),
  );
}

class SenderIdSheet extends StatefulWidget {
  const SenderIdSheet({super.key, required this.store, required this.current});

  final SenderIdStore store;
  final String current;

  @override
  State<SenderIdSheet> createState() => _SenderIdSheetState();
}

class _SenderIdSheetState extends State<SenderIdSheet> {
  bool _showHistory = false;
  late Future<List<String>> _saved = widget.store.loadSaved();
  late Future<List<String>> _history = widget.store.loadHistory();

  String get _current => widget.current.trim();

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Absender-Historie leeren?'),
        content: const Text(
          'Alle automatisch gemerkten Absenderkennungen werden entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leeren'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.store.clearHistory();
    if (mounted) {
      setState(() {
        _history = widget.store.loadHistory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: _showHistory ? _buildHistory() : _buildSaved(),
      ),
    );
  }

  Widget _buildSaved() {
    return FutureBuilder<List<String>>(
      future: _saved,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <String>[];
        final canSave = _current.isNotEmpty && !entries.contains(_current);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Gespeicherte Absenderkennungen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: TextButton.icon(
                onPressed: () => setState(() {
                  _showHistory = true;
                  _history = widget.store.loadHistory();
                }),
                icon: const Icon(Icons.history),
                label: const Text('Historie'),
              ),
            ),
            if (canSave)
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: Text('„$_current“ speichern'),
                onTap: () => setState(() {
                  _saved = widget.store.save(_current);
                }),
              ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Text(
                  'Noch keine gespeicherten Absenderkennungen. Eine Kennung im Feld eingeben und hier speichern.',
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final entry in entries)
                      ListTile(
                        leading: const Icon(Icons.bookmark_outline),
                        title: Text(entry),
                        onTap: () => Navigator.of(context).pop(entry),
                        trailing: IconButton(
                          tooltip: 'Entfernen',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() {
                            _saved = widget.store.unsave(entry);
                          }),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHistory() {
    return FutureBuilder<List<String>>(
      future: _history,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <String>[];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: IconButton(
                tooltip: 'Zurück',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _showHistory = false;
                  _saved = widget.store.loadSaved();
                }),
              ),
              title: const Text(
                'Absender-Historie',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: TextButton.icon(
                onPressed: entries.isEmpty ? null : _clearHistory,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Leeren'),
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Text(
                  'Noch keine Einträge. Verwendete Absenderkennungen werden nach dem Versand automatisch gemerkt.',
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final entry in entries)
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(entry),
                        onTap: () => Navigator.of(context).pop(entry),
                        trailing: IconButton(
                          tooltip: 'Speichern',
                          icon: const Icon(Icons.bookmark_add_outlined),
                          onPressed: () => setState(() {
                            _saved = widget.store.save(entry);
                          }),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
