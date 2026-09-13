import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/phone_number.dart';

class RecipientsField extends StatefulWidget {
  const RecipientsField({
    super.key,
    required this.name,
    required this.onPickContact,
    this.initialValue = const [],
  });

  final String name;
  final Future<String?> Function() onPickContact;
  final List<String> initialValue;

  @override
  State<RecipientsField> createState() => _RecipientsFieldState();
}

class _RecipientsFieldState extends State<RecipientsField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _merged(List<String>? value) {
    final pending = parseRecipients(_controller.text);
    return [
      ...?value,
      for (final number in pending)
        if (!(value ?? const []).contains(number)) number,
    ];
  }

  void _commit(FormFieldState<List<String>> field) {
    final merged = _merged(field.value);
    if (merged.length != (field.value?.length ?? 0)) {
      field.didChange(merged);
    }
    _controller.clear();
  }

  Future<void> _pick(FormFieldState<List<String>> field) async {
    final number = await widget.onPickContact();
    if (number == null) {
      return;
    }
    final normalized = normalizeRecipient(number);
    final current = field.value ?? const <String>[];
    if (normalized.isNotEmpty && !current.contains(normalized)) {
      field.didChange([...current, normalized]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<List<String>>(
      name: widget.name,
      initialValue: widget.initialValue,
      validator: (value) {
        final merged = _merged(value);
        return merged.isEmpty ? 'Feld darf nicht leer sein' : null;
      },
      valueTransformer: _merged,
      builder: (field) {
        final recipients = field.value ?? const <String>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onChanged: (_) => field.didChange(field.value ?? const []),
              onSubmitted: (_) => _commit(field),
              decoration: InputDecoration(
                labelText: recipients.isEmpty
                    ? 'Empfänger'
                    : 'Weiterer Empfänger',
                helperText: recipients.isEmpty
                    ? null
                    : '${recipients.length} ${recipients.length == 1 ? 'Empfänger' : 'Empfänger'}',
                errorText: field.errorText,
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _commit(field),
                      tooltip: 'Empfänger hinzufügen',
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      onPressed: () => _pick(field),
                      tooltip: 'Aus Kontakten',
                      icon: const Icon(Icons.contacts),
                    ),
                  ],
                ),
              ),
            ),
            if (recipients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 0,
                  children: [
                    for (final number in recipients)
                      InputChip(
                        label: Text(number),
                        onDeleted: () => field.didChange(
                          recipients.where((item) => item != number).toList(),
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
