import 'package:firmensms/modals/about.dart';
import 'package:firmensms/pages/settings.dart';
import 'package:flutter/foundation.dart';
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
    // Build a Form widget using the _formKey created above.
    return Scaffold(
        appBar: AppBar(
          title: const Text("Firmensms"),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) { return const AboutModal(); }
                  );
                },
                icon: const Icon(Icons.info_outline)
            ),
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
                icon: const Icon(Icons.settings)
            )
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
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 7),
                  child: FormBuilderTextField(
                    name: 'senderid',
                    maxLength: 17,
                    decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () => {openContactFrom()},
                          icon: const Icon(Icons.contacts),
                        ),
                      counter: SizedBox.shrink(),
                      labelText: 'Absenderkennung',
                        border: const OutlineInputBorder(),
                    )
                )),
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
                          counter: SizedBox.shrink(),
                          labelText: 'Empfänger',
                          border: const OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.required(context, errorText: "Feld darf nicht leer sein")
                    )),
                Container(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 7),
                    child: Row(
                      children: [
                        Flexible(
                            child: Container(
                                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                child: FormBuilderDropdown(
                                    name: 'route',
                                    initialValue: "5 (EUR 0,075)",
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
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList()))),
                        Flexible(
                            child: FormBuilderDropdown(
                                name: "type",
                                initialValue: "Normal",
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Typ',
                                    counter: SizedBox.shrink()),
                                items: <String>[
                                  "Normal",
                                  "Voice",
                                  "Flash"
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList()))
                      ],
                    )),
                Container(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 7),
                    child: FormBuilderTextField(
                        name: 'text',
                        maxLength: 1000,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          counter: SizedBox.shrink(),
                          labelText: 'Nachricht',
                          border: OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.required(context, errorText: "Feld darf nicht leer sein")
                    )),
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
                ])
              ],
            ),
          )
        ])));
  }

  Future<void> openContactFrom() async {
    final fromContact = await FlutterContactPicker.pickPhoneContact(askForPermission: true);
    _formKey.currentState!.fields['senderid']!.didChange(fromContact.phoneNumber?.number);
  }

  Future<void> openContactTo() async {
    final toContact = await FlutterContactPicker.pickPhoneContact(askForPermission: true);
    _formKey.currentState!.fields['to']!.didChange(toContact.phoneNumber?.number);
  }

  void send() {
    if (kDebugMode) {
      print("Sending!");
    }
  }
}
