import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storage = const FlutterSecureStorage();
  var username = "";

  Future getUsername() async {
    return _storage.read(key: "username");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Einstellungen')),
        body: FutureBuilder(
          builder: (context, snapshot) {
            if (!snapshot.hasData &&
                snapshot.connectionState == ConnectionState.none) {
              return SizedBox(
                height: MediaQuery.of(context).size.height / 1.3,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.data != null) username = snapshot.data as String;
            return buildSettingsList(snapshot);
          },
          future: getUsername(),
        ));
  }

  Widget buildSettingsList(AsyncSnapshot<Object?> snapshot) {
    return SettingsList(
      sections: [
        SettingsSection(
          title: Text('Authentifizierung'),
          tiles: [
            SettingsTile(
              title: Text('Benutzername'),
              value: Text(username.isNotEmpty ? username : "(noch nicht gesetzt)"),
              leading: const Icon(Icons.person),
              onPressed: (context) {
                askForUsername();
              },
            ),
            SettingsTile(
              title: Text('Passwort (Programmspezifisch)'),
              value: Text('(verborgen)'),
              leading: const Icon(Icons.vpn_key),
              onPressed: (context) {
                askForPassword();
              },
            )
          ],
        )
      ],
    );
  }

  Future<void> askForUsername() async {
    var username = await prompt(context,
        title: const Text("Benutzername"),
        hintText: "Benutzername eingeben",
        barrierDismissible: true, validator: (String? value) {
      if (value == null || value.isEmpty) {
        return 'Feld darf nicht leer sein';
      }
      return null;
    }, initialValue: this.username, textCancel: const Text("Abbrechen"));

    if (username != null) {
      _storage.write(key: "username", value: username);
      setState(() {
        this.username = username;
      });
    }
  }

  Future<void> askForPassword() async {
    var password = await prompt(context,
        title: const Text("Passwort"),
        hintText: "Passwort eingeben",
        barrierDismissible: true, validator: (String? value) {
      if (value == null || value.isEmpty) {
        return 'Feld darf nicht leer sein';
      }
      return null;
    }, obscureText: true, textCancel: const Text("Abbrechen"));

    if (password != null) {
      _storage.write(key: "password", value: password);
    }
  }
}
