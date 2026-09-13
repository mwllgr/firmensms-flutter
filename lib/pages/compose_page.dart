import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';

import '../models/history_entry.dart';
import '../models/message_template.dart';
import '../models/sms_message.dart';
import '../models/sms_result.dart';
import '../services/history_store.dart';
import '../services/sender_id_store.dart';
import '../services/sms_api_client.dart';
import '../utils/phone_number.dart';
import '../utils/template_variables.dart';
import '../widgets/about_dialog.dart';
import '../widgets/send_dialog.dart';
import '../widgets/sender_id_sheet.dart';
import '../widgets/template_variables_dialog.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'templates_page.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({
    super.key,
    this.client,
    this.historyStore,
    this.senderIdStore,
  });

  final SmsApiClient? client;
  final HistoryStore? historyStore;
  final SenderIdStore? senderIdStore;

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  static const String _senderField = 'senderid';
  static const String _toField = 'to';
  static const String _routeField = 'route';
  static const String _typeField = 'type';
  static const String _textField = 'text';
  static const String _encodingField = 'encoding';
  static const String _requiredMessage = 'Feld darf nicht leer sein';

  final _formKey = GlobalKey<FormBuilderState>();
  final _contactPicker = FlutterNativeContactPicker();
  late final SmsApiClient _client = widget.client ?? SmsApiClient();
  late final HistoryStore _history = widget.historyStore ?? HistoryStore();
  late final SenderIdStore _senderIds = widget.senderIdStore ?? SenderIdStore();

  Future<void> _pickContact(String field) async {
    final contact = await _contactPicker.selectPhoneNumber();
    final number =
        contact?.selectedPhoneNumber ?? contact?.phoneNumbers?.firstOrNull;
    if (number != null) {
      _formKey.currentState?.fields[field]?.didChange(number);
    }
  }

  Future<void> _pickSenderId() async {
    final current =
        _formKey.currentState?.fields[_senderField]?.value as String?;
    final senderId = await showSenderIdSheet(
      context,
      store: _senderIds,
      current: current ?? '',
    );
    if (senderId != null) {
      _formKey.currentState?.fields[_senderField]?.didChange(senderId);
    }
  }

  Future<void> _openHistory() async {
    final message = await Navigator.of(context).push<SmsMessage>(
      MaterialPageRoute(builder: (context) => HistoryPage(store: _history)),
    );
    if (message != null) {
      _applyMessage(message);
    }
  }

  void _applyMessage(SmsMessage message) {
    final fields = _formKey.currentState?.fields;
    if (fields == null) {
      return;
    }
    fields[_senderField]?.didChange(message.senderId ?? '');
    fields[_toField]?.didChange(message.to);
    fields[_routeField]?.didChange(message.route);
    fields[_typeField]?.didChange(message.type);
    fields[_textField]?.didChange(message.text);
    fields[_encodingField]?.didChange(message.forceIso88591);
  }

  Future<SmsResult> _sendAndRecord(SmsMessage message) async {
    final id = _history.newId();
    final sentAt = DateTime.now();
    try {
      final result = await _client.send(message);
      await _history.add(
        HistoryEntry(
          id: id,
          sentAt: sentAt,
          message: message,
          success: true,
          result: result,
        ),
      );
      if (message.hasSenderId) {
        await _senderIds.remember(message.senderId!);
      }
      return result;
    } on SmsException catch (error) {
      await _history.add(
        HistoryEntry(
          id: id,
          sentAt: sentAt,
          message: message,
          success: false,
          error: error.message,
        ),
      );
      rethrow;
    }
  }

  Future<void> _insertTemplate() async {
    final currentText =
        _formKey.currentState?.fields[_textField]?.value as String?;
    final template = await Navigator.of(context).push<MessageTemplate>(
      MaterialPageRoute(
        builder: (context) => TemplatesPage(initialText: currentText ?? ''),
      ),
    );
    if (template == null || !mounted) {
      return;
    }
    var values = const <String, String>{};
    final variables = template.variables;
    if (variables.isNotEmpty) {
      final entered = await showTemplateVariablesDialog(
        context,
        variables: variables,
      );
      if (entered == null) {
        return;
      }
      values = entered;
    }
    final fields = _formKey.currentState?.fields;
    fields?[_textField]?.didChange(renderTemplate(template.text, values));
    if (template.hasSenderId) {
      fields?[_senderField]?.didChange(template.senderId);
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  SmsMessage _buildMessage() {
    final values = _formKey.currentState!.value;
    return SmsMessage(
      senderId: normalizeSenderId(values[_senderField] as String?),
      to: normalizeRecipient(values[_toField] as String),
      route: values[_routeField] as SmsRoute,
      type: values[_typeField] as SmsType,
      text: values[_textField] as String,
      forceIso88591: values[_encodingField] as bool? ?? false,
    );
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }
    final message = _buildMessage();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(message: message),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final result = _sendAndRecord(message);
    await showDialog<void>(
      context: context,
      builder: (context) => SendDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firmensms'),
        actions: [
          IconButton(
            onPressed: _insertTemplate,
            tooltip: 'Vorlagen',
            icon: const Icon(
              Icons.description_outlined,
              semanticLabel: 'Vorlagen',
            ),
          ),
          IconButton(
            onPressed: _openHistory,
            tooltip: 'Verlauf',
            icon: const Icon(Icons.history, semanticLabel: 'Verlauf'),
          ),
          IconButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => const AboutModal(),
            ),
            tooltip: 'Über',
            icon: const Icon(Icons.info_outline, semanticLabel: 'Über'),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const SettingsPage(),
              ),
            ),
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.settings, semanticLabel: 'Einstellungen'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 23, 15, 7),
                  child: FormBuilderTextField(
                    name: _senderField,
                    maxLength: 17,
                    decoration: InputDecoration(
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _pickSenderId,
                            tooltip: 'Gespeicherte Absenderkennungen',
                            icon: const Icon(
                              Icons.arrow_drop_down_circle_outlined,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _pickContact(_senderField),
                            tooltip: 'Aus Kontakten',
                            icon: const Icon(Icons.contacts),
                          ),
                        ],
                      ),
                      counter: const SizedBox.shrink(),
                      labelText: 'Absenderkennung',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 7),
                  child: FormBuilderTextField(
                    name: _toField,
                    maxLength: 17,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () => _pickContact(_toField),
                        icon: const Icon(Icons.contacts),
                      ),
                      counter: const SizedBox.shrink(),
                      labelText: 'Empfänger',
                      border: const OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: _requiredMessage,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 7),
                  child: Row(
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: FormBuilderDropdown<SmsRoute>(
                            name: _routeField,
                            initialValue: SmsRoute.route5,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Route',
                            ),
                            items: [
                              for (final route in SmsRoute.values)
                                DropdownMenuItem(
                                  value: route,
                                  child: Text(route.label),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Flexible(
                        child: FormBuilderDropdown<SmsType>(
                          name: _typeField,
                          initialValue: SmsType.normal,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Typ',
                          ),
                          items: [
                            for (final type in SmsType.values)
                              DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: FormBuilderTextField(
                    name: _textField,
                    maxLength: 1000,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      counter: SizedBox.shrink(),
                      labelText: 'Nachricht',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: _requiredMessage,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Zurücksetzen'),
                        style: FilledButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.redAccent,
                        ),
                        onPressed: _reset,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Text('Senden'),
                        label: const Icon(Icons.send),
                        style: FilledButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent,
                        ),
                        onPressed: _send,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                  child: FormBuilderCheckbox(
                    name: _encodingField,
                    initialValue: false,
                    activeColor: Colors.blueAccent,
                    title: const Text('ISO-8859-1 erzwingen'),
                    subtitle: const Text(
                      'Auch, wenn UTF-8-Inhalte erkannt werden',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.message});

  final SmsMessage message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wirklich senden?'),
      content: Text(
        'Soll die Nachricht wirklich gesendet werden?\n\n'
        '${message.hasSenderId ? 'Absender: ${message.senderId}\n' : ''}'
        'Empfänger: ${message.to}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Senden'),
        ),
      ],
    );
  }
}
