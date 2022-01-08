import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({Key? key}) : super(key: key);

  @override
  _ComposePageState createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _formKey = GlobalKey<FormState>();
  String route = '5 (EUR 0,075)';
  String type = 'Normal';

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Scaffold(
        appBar: AppBar(
          title: const Text("Firmensms"),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: SingleChildScrollView(
            child: Column(children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Feld darf nicht leer sein';
                            }
                            return null;
                          },
                          onSaved: (String? value) {

                          },
                          maxLength: 17,
                          onFieldSubmitted: (_) {
                            // showFinishDialog(context);
                          },
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                onPressed: () => {
                                  openContactFrom()
                                },
                                icon: const Icon(Icons.contacts),
                              ),
                              border: const OutlineInputBorder(),
                              labelText: 'Absenderkennung',
                              counter: const SizedBox.shrink()),
                        )),
                    Container(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 7),
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Feld darf nicht leer sein';
                            }
                            return null;
                          },
                          onSaved: (String? value) {},
                          maxLength: 17,
                          onFieldSubmitted: (_) {
                            // showFinishDialog(context);
                          },
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                onPressed: () => {
                                  openContactTo()
                                },
                                icon: const Icon(Icons.contacts),
                              ),
                              border: const OutlineInputBorder(),
                              labelText: 'Empfänger-Nr.',
                              counter: const SizedBox.shrink()),
                        )),
                    Container(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 7),
                        child: Row(
                          children: [
                            Flexible(
                                child: Container(
                                    padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                    child: DropdownButtonFormField(
                                        value: route,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            route = newValue!;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Route',
                                            counter: SizedBox.shrink()),
                                        items: <String>[
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
                                child: DropdownButtonFormField(
                                    value: type,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        type = newValue!;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Typ',
                                        counter: SizedBox.shrink()),
                                    items: <String>["Normal", "Voice", "Flash"]
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList()))
                          ],
                        )),
                    Container(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Feld darf nicht leer sein';
                            }
                            return null;
                          },
                          onSaved: (String? value) {},
                          maxLength: 1000,
                          maxLines: 6,
                          onFieldSubmitted: (_) {
                            // showFinishDialog(context);
                          },
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Nachricht',
                              counter: SizedBox.shrink()),
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
    if (kDebugMode) {
      print(fromContact.phoneNumber?.number);
    }
  }

  Future<void> openContactTo() async {
    final toContact = await FlutterContactPicker.pickPhoneContact(askForPermission: true);
    if (kDebugMode) {
      print(toContact.phoneNumber?.number);
    }
  }

  void send() {
    if (kDebugMode) {
      print("Sending!");
    }
  }
}