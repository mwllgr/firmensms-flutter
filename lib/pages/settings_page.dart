import 'package:material_ui/material_ui.dart';

import '../services/credentials_store.dart';
import '../widgets/text_prompt_dialog.dart';
import 'onboarding_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.store = const CredentialsStore()});

  final CredentialsStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<String?> _username = widget.store.readUsername();

  Future<void> _askForUsername(String current) async {
    final username = await showTextPromptDialog(
      context,
      title: 'Benutzername',
      hintText: 'Benutzername eingeben',
      initialValue: current,
    );
    if (username == null) {
      return;
    }
    await widget.store.writeUsername(username);
    if (mounted) {
      setState(() {
        _username = Future.value(username);
      });
    }
  }

  Future<void> _askForPassword() async {
    final password = await showTextPromptDialog(
      context,
      title: 'Passwort',
      hintText: 'Passwort eingeben',
      obscureText: true,
    );
    if (password != null) {
      await widget.store.writePassword(password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<String?>(
          future: _username,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final username = snapshot.data ?? '';
            return ListView(
              children: [
                const _SectionTitle('Authentifizierung'),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Benutzername'),
                  subtitle: Text(
                    username.isNotEmpty ? username : '(noch nicht gesetzt)',
                  ),
                  onTap: () => _askForUsername(username),
                ),
                ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: const Text('Passwort (Programmspezifisch)'),
                  subtitle: const Text('(verborgen)'),
                  onTap: _askForPassword,
                ),
                const _SectionTitle('Hilfe'),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Einführung erneut anzeigen'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (context) => OnboardingPage(
                        credentials: widget.store,
                        onFinished: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
