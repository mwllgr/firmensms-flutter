import 'package:material_ui/material_ui.dart';

Future<Map<String, String>?> showTemplateVariablesDialog(
  BuildContext context, {
  required List<String> variables,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => TemplateVariablesDialog(variables: variables),
  );
}

class TemplateVariablesDialog extends StatefulWidget {
  const TemplateVariablesDialog({super.key, required this.variables});

  final List<String> variables;

  @override
  State<TemplateVariablesDialog> createState() =>
      _TemplateVariablesDialogState();
}

class _TemplateVariablesDialogState extends State<TemplateVariablesDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final name in widget.variables) name: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop({
        for (final entry in _controllers.entries) entry.key: entry.value.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Variablen ausfüllen'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, name) in widget.variables.indexed)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                  child: TextFormField(
                    controller: _controllers[name],
                    autofocus: index == 0,
                    textInputAction: index == widget.variables.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: name,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Feld darf nicht leer sein'
                        : null,
                    onFieldSubmitted: (_) {
                      if (index == widget.variables.length - 1) {
                        _submit();
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(onPressed: _submit, child: const Text('Einfügen')),
      ],
    );
  }
}
