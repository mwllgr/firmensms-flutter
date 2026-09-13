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
  late Future<List<String>> _entries = widget.store.loadAll();

  String get _current => widget.current.trim();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<String>>(
        future: _entries,
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <String>[];
          final canSave = _current.isNotEmpty && !entries.contains(_current);
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Absenderkennung wählen',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (canSave)
                  ListTile(
                    leading: const Icon(Icons.bookmark_add_outlined),
                    title: Text('„$_current“ speichern'),
                    onTap: () => setState(() {
                      _entries = widget.store.remember(_current);
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
                      'Noch keine Einträge. Verwendete Absenderkennungen werden nach dem Versand automatisch gespeichert.',
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
                              tooltip: 'Entfernen',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => setState(() {
                                _entries = widget.store.forget(entry);
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
