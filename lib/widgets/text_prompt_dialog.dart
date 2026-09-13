import 'package:material_ui/material_ui.dart';

Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  required String hintText,
  String initialValue = '',
  bool obscureText = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => TextPromptDialog(
      title: title,
      hintText: hintText,
      initialValue: initialValue,
      obscureText: obscureText,
    ),
  );
}

class TextPromptDialog extends StatefulWidget {
  const TextPromptDialog({
    super.key,
    required this.title,
    required this.hintText,
    this.initialValue = '',
    this.obscureText = false,
  });

  final String title;
  final String hintText;
  final String initialValue;
  final bool obscureText;

  @override
  State<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<TextPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          obscureText: widget.obscureText,
          autocorrect: !widget.obscureText,
          enableSuggestions: !widget.obscureText,
          decoration: InputDecoration(hintText: widget.hintText),
          validator: (value) => value == null || value.isEmpty
              ? 'Feld darf nicht leer sein'
              : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}
