import 'dart:convert';

import 'package:firmensms/modals/about.dart';
import 'package:firmensms/modals/send.dart';
import 'package:firmensms/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({Key? key}) : super(key: key);

  @override
  _ComposePageState createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  String route = '5 (EUR 0,075)';
  String type = 'Normal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Firmensms"),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const AboutModal();
                      });
                },
                tooltip: 'Über',
                icon: const Icon(
                  Icons.info_outline,
                  semanticLabel: 'Über',
                )),
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                },
                tooltip: 'Einstellungen',
                icon:
                    const Icon(Icons.settings, semanticLabel: 'Einstellungen'))
          ],
        ),
        body: SingleChildScrollView(
            child: Column(children: [
          FormBuilder(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.fromLTRB(15, 23, 15, 7),
                    child: FormBuilderTextField(
                        name: 'senderid',
                        maxLength: 17,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            onPressed: () => {openContactFrom()},
                            icon: const Icon(Icons.contacts),
                          ),
                          counter: const SizedBox.shrink(),
                          labelText: 'Absenderkennung',
                          border: const OutlineInputBorder(),
                        ))),
                Container(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 7),
                    child: FormBuilderTextField(
                        name: 'to',
                        maxLength: 17,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            onPressed: () => {openContactTo()},
                            icon: const Icon(Icons.contacts),
                          ),
                          counter: const SizedBox.shrink(),
                          labelText: 'Empfänger',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: FormBuilderValidators.required(context,
                            errorText: "Feld darf nicht leer sein"))),
                Container(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 7),
                    child: Row(
                      children: [
                        Flexible(
                            child: Container(
                                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                child: FormBuilderDropdown(
                                    name: 'route',
                                    initialValue: "5",
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Route',
                                        counter: SizedBox.shrink()),
                                    items: [
                                      "3 (EUR 0,085)",
                                      "5 (EUR 0,075)",
                                      "6 (EUR 0,05)"
                                    ].map<DropdownMenuItem<String>>(
                                        (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value.substring(0, 1),
                                        child: Text(value),
                                      );
                                    }).toList()))),
                        Flexible(
                            child: FormBuilderDropdown(
                                name: "type",
                                initialValue: "normal",
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Typ',
                                    counter: SizedBox.shrink()),
                                items: <String>["Normal", "Voice", "Flash"]
                                    .map<DropdownMenuItem<String>>((String v) {
                                  return DropdownMenuItem<String>(
                                    value: v.toLowerCase(),
                                    child: Text(v),
                                  );
                                }).toList()))
                      ],
                    )),
                Container(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                    child: FormBuilderTextField(
                        name: 'text',
                        maxLength: 1000,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          counter: SizedBox.shrink(),
                          labelText: 'Nachricht',
                          border: OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.required(context,
                            errorText: "Feld darf nicht leer sein"))),
                Row(children: [
                  Container(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                      child: TextButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Zurücksetzen'),
                        style: TextButton.styleFrom(
                          primary: Colors.white,
                          backgroundColor: Colors.redAccent,
                          onSurface: Colors.grey,
                        ),
                        onPressed: () {
                          _formKey.currentState?.reset();
                          FocusScope.of(context).unfocus();
                        },
                      )),
                  const Spacer(),
                  Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
                      child: TextButton.icon(
                        icon: const Text('Senden'),
                        label: const Icon(Icons.send),
                        style: TextButton.styleFrom(
                          primary: Colors.white,
                          backgroundColor: Colors.blueAccent,
                          onSurface: Colors.grey,
                        ),
                        onPressed: () {
                          send();
                        },
                      ))
                ]),
                Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                    child: FormBuilderCheckbox(
                      name: 'encoding',
                      initialValue: false,
                      subtitle:
                          const Text("Auch, wenn UTF-8-Inhalte erkannt werden"),
                      title: const Text("ISO-8859-1 erzwingen"),
                    )),
              ],
            ),
          )
        ])));
  }

  Future<void> openContactFrom() async {
    final fromContact =
        await FlutterContactPicker.pickPhoneContact(askForPermission: true);
    _formKey.currentState!.fields['senderid']!
        .didChange(fromContact.phoneNumber?.number);
  }

  Future<void> openContactTo() async {
    final toContact =
        await FlutterContactPicker.pickPhoneContact(askForPermission: true);
    _formKey.currentState!.fields['to']!
        .didChange(toContact.phoneNumber?.number);
  }

  void send() {
    if (_formKey.currentState!.saveAndValidate()) {
      askSendConfirmation(context);
    }
  }

  void askSendConfirmation(BuildContext context) {
    var data = sanitizeData();

    Widget cancelButton = TextButton(
      child: const Text("Abbrechen"),
      onPressed: () {},
    );
    Widget continueButton = TextButton(
      child: const Text("Senden"),
      onPressed: () {
        Navigator.pop(context);
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return SendModal(json: json.encode(data));
            });
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Wirklich senden?"),
      content: Text("Soll die Nachricht wirklich gesendet werden?\n\n" +
          (data!["senderid"].toString().isNotEmpty && data["senderid"] != null
              ? "Absender: " + data["senderid"] + "\n"
              : "") +
          "Empfänger: " +
          data["to"]),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Map<String, dynamic>? sanitizeData() {
    var data = Map<String, dynamic>.from(_formKey.currentState!.value);

    // Encoding
    if (data["encoding"]) {
      data["encoding"] = "ISO-8859-1";
    } else {
      data["encoding"] = "auto";
    }

    // Type
    if (data["type"] == "normal") data.remove("type");

    // To
    var to = data["to"].toString();
    if (to.startsWith('+')) to = to.replaceFirst('+', '00');
    if (to.startsWith('0') && !to.startsWith('00')) {
      to = to.replaceFirst('0', '0043');
    }
    data["to"] = to.replaceAll(RegExp(r'[^0-9]'), '');

    // From
    if (data["senderid"] != null) {
      var senderid = data["senderid"].toString();

      if (senderid.startsWith('+')) {
        senderid =
            senderid.replaceFirst('+', '00').replaceAll(RegExp(r'[^0-9]'), '');
      }
      var noSpaces = senderid.replaceAll(' ', '');

      if (noSpaces.startsWith('0') &&
          !noSpaces.startsWith('00') &&
          !RegExp(r'(?!^\d+$)^.+$').hasMatch(noSpaces)) {
        senderid = noSpaces.replaceFirst('0', '0043');
      }

      data["senderid"] = senderid;
    } else {
      data.remove("senderid");
    }

    return data;
  }
}
