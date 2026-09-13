import 'package:material_ui/material_ui.dart';

import '../models/message_template.dart';
import '../utils/template_variables.dart';

class TemplateEditPage extends StatefulWidget {
  const TemplateEditPage({super.key, required this.template});

  final MessageTemplate template;

  @override
  State<TemplateEditPage> createState() => _TemplateEditPageState();
}

class _TemplateEditPageState extends State<TemplateEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.template.name);
  late final _senderId = TextEditingController(
    text: widget.template.senderId ?? '',
  );
  late final _text = TextEditingController(text: widget.template.text);

  bool get _isNew => widget.template.name.isEmpty;

  @override
  void dispose() {
    _name.dispose();
    _senderId.dispose();
    _text.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      widget.template.copyWith(
        name: _name.text.trim(),
        text: _text.text,
        senderId: _senderId.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final variables = extractCustomPlaceholders(_text.text);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Neue Vorlage' : 'Vorlage bearbeiten'),
        actions: [
          IconButton(
            onPressed: _save,
            tooltip: 'Speichern',
            icon: const Icon(Icons.check, semanticLabel: 'Speichern'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(15, 23, 15, 15),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Feld darf nicht leer sein'
                      : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _senderId,
                  maxLength: 17,
                  decoration: const InputDecoration(
                    labelText: 'Absenderkennung (optional)',
                    counter: SizedBox.shrink(),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _text,
                  maxLength: 1000,
                  maxLines: 8,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Nachricht',
                    counter: SizedBox.shrink(),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Feld darf nicht leer sein'
                      : null,
                ),
                const SizedBox(height: 15),
                Text(
                  'Variablen werden in geschweiften Klammern geschrieben, z. B. {name}. '
                  'Beim Einfügen der Vorlage wird nach den Werten gefragt. '
                  '{datum} und {uhrzeit} werden automatisch ausgefüllt.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (variables.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final name in variables) Chip(label: Text(name)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
