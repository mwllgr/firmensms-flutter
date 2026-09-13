import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'pages/compose_page.dart';
import 'pages/onboarding_page.dart';
import 'services/onboarding_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const SmsApp());
}

class SmsApp extends StatelessWidget {
  const SmsApp({super.key, this.onboarding, this.showOnboarding});

  final OnboardingStore? onboarding;
  final bool? showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firmensms',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: showOnboarding == null
          ? StartPage(onboarding: onboarding ?? OnboardingStore())
          : (showOnboarding! ? const _OnboardingStart() : const ComposePage()),
    );
  }
}

class StartPage extends StatefulWidget {
  const StartPage({super.key, required this.onboarding});

  final OnboardingStore onboarding;

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  late final Future<bool> _completed = widget.onboarding.isCompleted();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _completed,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return snapshot.data!
            ? const ComposePage()
            : _OnboardingStart(onboarding: widget.onboarding);
      },
    );
  }
}

class _OnboardingStart extends StatelessWidget {
  const _OnboardingStart({this.onboarding});

  final OnboardingStore? onboarding;

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      onboarding: onboarding,
      onFinished: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (context) => const ComposePage()),
      ),
    );
  }
}
