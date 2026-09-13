import 'package:material_ui/material_ui.dart';

import '../models/message_template.dart';
import '../services/template_store.dart';
import 'template_edit_page.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key, this.store, this.initialText = ''});

  final TemplateStore? store;
  final String initialText;

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  late final TemplateStore _store = widget.store ?? TemplateStore();
  late Future<List<MessageTemplate>> _templates = _store.loadAll();

  Future<void> _edit(MessageTemplate template) async {
    final result = await Navigator.of(context).push<MessageTemplate>(
      MaterialPageRoute(
        builder: (context) => TemplateEditPage(template: template),
      ),
    );
    if (result == null) {
      return;
    }
    final updated = _store.upsert(result);
    setState(() {
      _templates = updated;
    });
  }

  Future<void> _create() => _edit(
    MessageTemplate(id: _store.newId(), name: '', text: widget.initialText),
  );

  Future<void> _delete(MessageTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vorlage löschen?'),
        content: Text('Soll die Vorlage „${template.name}“ gelöscht werden?'),
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
    if (confirmed != true) {
      return;
    }
    final updated = _store.delete(template.id);
    setState(() {
      _templates = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vorlagen')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Neue Vorlage'),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<MessageTemplate>>(
          future: _templates,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final templates = snapshot.data ?? const <MessageTemplate>[];
            if (templates.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'Noch keine Vorlagen vorhanden.\nMit „Neue Vorlage“ kann eine Vorlage angelegt werden.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(template.name),
                  subtitle: Text(
                    template.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(context).pop(template),
                  trailing: PopupMenuButton<_TemplateAction>(
                    tooltip: 'Optionen',
                    onSelected: (action) => switch (action) {
                      _TemplateAction.edit => _edit(template),
                      _TemplateAction.delete => _delete(template),
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _TemplateAction.edit,
                        child: Text('Bearbeiten'),
                      ),
                      PopupMenuItem(
                        value: _TemplateAction.delete,
                        child: Text('Löschen'),
                      ),
                    ],
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

enum _TemplateAction { edit, delete }
