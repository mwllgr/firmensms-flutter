import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutModal extends StatelessWidget {
  const AboutModal({super.key});

  static final Uri projectUrl = Uri.parse(
    'https://github.com/mwllgr/firmensms-flutter',
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Icon(Icons.info, size: 70, color: Colors.orange),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Über diese App',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 15),
              child: Text(
                'Diese Open-Source-App wurde von insComers entwickelt und ist keine offizielle App von firmensms.at.\n\n'
                'Das firmensms-Logo bzw. die verwendete REST-Schnittstelle ist Eigentum der Missus GmbH.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: FilledButton.icon(
                icon: const Text('Zur Projektseite (Github)'),
                label: const Icon(Icons.open_in_new),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                ),
                onPressed: () => launchUrl(projectUrl),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 5),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK', style: TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }
}
