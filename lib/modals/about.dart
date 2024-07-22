import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutModal extends StatelessWidget {
  const AboutModal({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
          child: Column(
        children: [
          const Icon(
            Icons.info,
            size: 70,
            color: Colors.orange,
          ),
          const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: Text('Über diese App',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
          const Padding(
              padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
              child: Text(
                  'Diese Open-Source-App wurde von insComers entwickelt und ist keine offizielle App von firmensms.at.\n\n'
                      'Das firmensms-Logo bzw. die verwendete REST-Schnittstelle ist Eigentum der Missus GmbH.')),
          Padding(
              padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              child: TextButton.icon(
                  icon: const Text('Zur Projektseite (Github)'),
                  label: const Icon(Icons.open_in_new),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.orange, disabledForegroundColor: Colors.grey.withOpacity(0.38),
                  ),
                  onPressed: () {
                    launchUrl(Uri.parse("https://github.com/mwllgr/firmensms-flutter"));
                  }))
        ],
      )),
      actionsPadding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
      actions: [
        TextButton(
          child: const Text('OK', style: TextStyle(color: Colors.orange)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
