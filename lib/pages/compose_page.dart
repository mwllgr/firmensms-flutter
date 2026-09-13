import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';

import '../models/message_template.dart';
import '../models/send_plan.dart';
import '../models/sms_message.dart';
import '../services/credentials_store.dart';
import '../services/history_store.dart';
import '../services/message_sender.dart';
import '../services/sender_id_store.dart';
import '../utils/phone_number.dart';
import '../utils/template_variables.dart';
import '../widgets/about_dialog.dart';
import '../widgets/recipients_field.dart';
import '../widgets/send_progress_dialog.dart';
import '../widgets/sender_id_sheet.dart';
import '../widgets/template_variables_dialog.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'templates_page.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({
    super.key,
    this.sender,
    this.historyStore,
    this.senderIdStore,
    this.credentials = const CredentialsStore(),
  });

  final MessageSender? sender;
  final HistoryStore? historyStore;
  final SenderIdStore? senderIdStore;
  final CredentialsStore credentials;

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
  static const String _countField = 'count';
  static const String _autoField = 'auto';
  static const String _intervalField = 'interval';
  static const String _requiredMessage = 'Feld darf nicht leer sein';
  static const int _maxCount = 100;
  static const int _minIntervalSeconds = 5;

  final _formKey = GlobalKey<FormBuilderState>();
  final _contactPicker = FlutterNativeContactPicker();
  late final HistoryStore _history = widget.historyStore ?? HistoryStore();
  late final SenderIdStore _senderIds = widget.senderIdStore ?? SenderIdStore();
  late final MessageSender _sender =
      widget.sender ??
      MessageSender(historyStore: _history, senderIdStore: _senderIds);
  bool _hasCredentials = true;
  bool _showAdvanced = false;
  bool _autoSend = false;

  @override
  void initState() {
    super.initState();
    _checkCredentials();
  }

  Future<void> _checkCredentials() async {
    final available = await widget.credentials.hasCredentials();
    if (mounted && available != _hasCredentials) {
      setState(() => _hasCredentials = available);
    }
  }

  Future<String?> _pickContactNumber() async {
    final contact = await _contactPicker.selectPhoneNumber();
    return contact?.selectedPhoneNumber ?? contact?.phoneNumbers?.firstOrNull;
  }

  Future<void> _pickSenderContact() async {
    final number = await _pickContactNumber();
    if (number != null) {
      _formKey.currentState?.fields[_senderField]?.didChange(number);
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

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const SettingsPage()));
    await _checkCredentials();
  }

  Future<void> _openHistory() async {
    final message = await Navigator.of(context).push<SmsMessage>(
      MaterialPageRoute(
        builder: (context) => HistoryPage(store: _history, sender: _sender),
      ),
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
    fields[_toField]?.didChange(<String>[message.to]);
    fields[_routeField]?.didChange(message.route);
    fields[_typeField]?.didChange(message.type);
    fields[_textField]?.didChange(message.text);
    fields[_encodingField]?.didChange(message.forceIso88591);
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
    setState(() => _autoSend = false);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  SendPlan _buildPlan() {
    final values = _formKey.currentState!.value;
    final message = SmsMessage(
      senderId: normalizeSenderId(values[_senderField] as String?),
      to: '',
      route: values[_routeField] as SmsRoute,
      type: values[_typeField] as SmsType,
      text: values[_textField] as String,
      forceIso88591: values[_encodingField] as bool? ?? false,
    );
    final auto = values[_autoField] as bool? ?? false;
    return SendPlan(
      message: message,
      recipients: (values[_toField] as List<String>?) ?? const [],
      count: int.tryParse(values[_countField] as String? ?? '') ?? 1,
      interval: auto
          ? Duration(seconds: int.parse(values[_intervalField] as String))
          : null,
    );
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }
    final plan = _buildPlan();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(plan: plan),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final messages = plan.messages;
    final interval = plan.interval;
    await showSendProgressDialog(
      context,
      outcomes: interval == null
          ? _sender.sendAll(messages)
          : _sender.sendRepeatedly(messages, interval: interval),
      total: interval == null ? messages.length : null,
      interval: interval,
    );
    await _checkCredentials();
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
            onPressed: _openSettings,
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.settings, semanticLabel: 'Einstellungen'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!_hasCredentials)
              MaterialBanner(
                leading: const Icon(Icons.vpn_key_outlined),
                content: const Text(
                  'Es sind noch keine Zugangsdaten hinterlegt. Ohne Benutzername und Passwort kann nichts gesendet werden.',
                ),
                actions: [
                  TextButton(
                    onPressed: _openSettings,
                    child: const Text('Einstellungen öffnen'),
                  ),
                ],
              ),
            Expanded(
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
                                  onPressed: _pickSenderContact,
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
                        child: RecipientsField(
                          name: _toField,
                          onPickContact: _pickContactNumber,
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
                      ListTile(
                        leading: Icon(
                          _showAdvanced ? Icons.expand_less : Icons.expand_more,
                        ),
                        title: const Text('Versandoptionen'),
                        subtitle: _autoSend
                            ? const Text('Automatischer Versand aktiv')
                            : null,
                        onTap: () =>
                            setState(() => _showAdvanced = !_showAdvanced),
                      ),
                      Visibility(
                        visible: _showAdvanced,
                        maintainState: true,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FormBuilderTextField(
                                name: _countField,
                                initialValue: '1',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Anzahl pro Empfänger',
                                  helperText: 'Sendet dieselbe Nachricht mehrfach an jeden Empfänger',
                                  border: OutlineInputBorder(),
                                ),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                    errorText: _requiredMessage,
                                  ),
                                  FormBuilderValidators.integer(
                                    errorText: 'Ganze Zahl eingeben',
                                  ),
                                  FormBuilderValidators.min(
                                    1,
                                    errorText: 'Mindestens 1',
                                  ),
                                  FormBuilderValidators.max(
                                    _maxCount,
                                    errorText: 'Höchstens $_maxCount',
                                  ),
                                ]),
                              ),
                              FormBuilderSwitch(
                                name: _autoField,
                                initialValue: false,
                                title: const Text('Automatisch wiederholen'),
                                subtitle: const Text(
                                  'Sendet die Nachricht in einem festen Abstand erneut, solange die App geöffnet ist',
                                ),
                                contentPadding: EdgeInsets.zero,
                                onChanged: (value) =>
                                    setState(() => _autoSend = value ?? false),
                              ),
                              if (_autoSend)
                                FormBuilderTextField(
                                  name: _intervalField,
                                  initialValue: '60',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Abstand in Sekunden',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(
                                      errorText: _requiredMessage,
                                    ),
                                    FormBuilderValidators.integer(
                                      errorText: 'Ganze Zahl eingeben',
                                    ),
                                    FormBuilderValidators.min(
                                      _minIntervalSeconds,
                                      errorText:
                                          'Mindestens $_minIntervalSeconds Sekunden',
                                    ),
                                  ]),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.plan});

  final SendPlan plan;

  @override
  Widget build(BuildContext context) {
    final message = plan.message;
    final recipients = plan.recipients;
    final lines = <String>[
      if (message.hasSenderId) 'Absender: ${message.senderId}',
      recipients.length == 1
          ? 'Empfänger: ${recipients.single}'
          : 'Empfänger (${recipients.length}):\n${recipients.join('\n')}',
      if (plan.count > 1) 'Anzahl pro Empfänger: ${plan.count}',
      if (plan.messagesPerRound > 1) 'SMS gesamt: ${plan.messagesPerRound}',
      if (plan.isAutomatic)
        'Automatischer Versand alle ${plan.interval!.inSeconds} Sekunden, bis er gestoppt wird. Jede Runde verursacht Kosten.',
    ];
    return AlertDialog(
      title: Text(
        plan.isAutomatic
            ? 'Automatischen Versand starten?'
            : 'Wirklich senden?',
      ),
      content: Text(
        '${plan.isAutomatic ? 'Soll der automatische Versand gestartet werden?' : 'Soll die Nachricht wirklich gesendet werden?'}\n\n'
        '${lines.join('\n')}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(plan.isAutomatic ? 'Starten' : 'Senden'),
        ),
      ],
    );
  }
}
