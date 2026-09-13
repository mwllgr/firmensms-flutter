import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/credentials_store.dart';
import '../services/onboarding_store.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onFinished,
    this.credentials = const CredentialsStore(),
    this.onboarding,
  });

  final VoidCallback onFinished;
  final CredentialsStore credentials;
  final OnboardingStore? onboarding;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static final Uri _websiteUrl = Uri.parse('https://www.firmensms.at');
  static const int _pageCount = 3;

  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  late final OnboardingStore _onboarding =
      widget.onboarding ?? OnboardingStore();
  int _page = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.credentials.readUsername().then((value) {
      if (mounted && value != null) {
        _username.text = value;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == 1 && !await _saveCredentials()) {
      return;
    }
    if (_page == _pageCount - 1) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<bool> _saveCredentials() async {
    if (_username.text.trim().isEmpty && _password.text.isEmpty) {
      return true;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }
    setState(() => _saving = true);
    await widget.credentials.writeUsername(_username.text.trim());
    await widget.credentials.writePassword(_password.text);
    if (mounted) {
      setState(() => _saving = false);
    }
    return true;
  }

  Future<void> _finish() async {
    await _onboarding.setCompleted(true);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _Step(
                    icon: Icons.sms_outlined,
                    title: 'Willkommen bei Firmensms',
                    children: [
                      const Text(
                        'Mit dieser App senden Sie SMS über Ihr Konto bei firmensms.at, '
                        'einzeln oder an mehrere Empfänger gleichzeitig.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Die App ist ein inoffizieller Open-Source-Client. '
                        'Sie benötigen ein bestehendes Konto bei firmensms.at.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(_websiteUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('firmensms.at öffnen'),
                      ),
                    ],
                  ),
                  _Step(
                    icon: Icons.vpn_key_outlined,
                    title: 'Zugangsdaten',
                    children: [
                      const Text(
                        'Geben Sie Ihren Benutzernamen und das programmspezifische Passwort ein. '
                        'Beides wird nur verschlüsselt auf diesem Gerät gespeichert.',
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _username,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Benutzername',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Feld darf nicht leer sein'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _next(),
                              decoration: const InputDecoration(
                                labelText: 'Passwort (Programmspezifisch)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Feld darf nicht leer sein'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sie können diesen Schritt überspringen und die Daten später in den Einstellungen eintragen.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const _Step(
                    icon: Icons.tips_and_updates_outlined,
                    title: 'Gut zu wissen',
                    children: [
                      _Tip(
                        icon: Icons.group_outlined,
                        text: 'Mehrere Empfänger: Nummer eingeben und mit + hinzufügen oder aus den Kontakten wählen.',
                      ),
                      _Tip(
                        icon: Icons.description_outlined,
                        text: 'Vorlagen mit Variablen wie {name} sparen Tipparbeit. {datum} und {uhrzeit} werden automatisch eingesetzt.',
                      ),
                      _Tip(
                        icon: Icons.history,
                        text: 'Der Verlauf zeigt alle gesendeten Nachrichten und erlaubt das erneute Senden.',
                      ),
                      _Tip(
                        icon: Icons.arrow_drop_down_circle_outlined,
                        text: 'Absenderkennungen lassen sich speichern; verwendete Kennungen landen automatisch in der Absender-Historie.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  const Spacer(),
                  if (_page < _pageCount - 1)
                    TextButton(
                      onPressed: _saving ? null : _finish,
                      child: const Text('Überspringen'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _next,
                    child: Text(
                      _page == _pageCount - 1 ? 'Los geht\'s' : 'Weiter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
