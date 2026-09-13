import 'package:firmensms/main.dart';
import 'package:firmensms/pages/onboarding_page.dart';
import 'package:firmensms/services/credentials_store.dart';
import 'package:firmensms/services/onboarding_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MemoryCredentials extends CredentialsStore {
  _MemoryCredentials() : super(const FlutterSecureStorage());

  String? username;
  String? password;

  @override
  Future<String?> readUsername() async => username;

  @override
  Future<void> writeUsername(String value) async => username = value;

  @override
  Future<void> writePassword(String value) async => password = value;

  @override
  Future<Credentials?> read() async => username == null || password == null
      ? null
      : (username: username!, password: password!);
}

void main() {
  late OnboardingStore onboarding;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    onboarding = OnboardingStore(preferences: SharedPreferencesAsync());
  });

  testWidgets('app starts with onboarding until it is completed', (
    tester,
  ) async {
    await tester.pumpWidget(SmsApp(onboarding: onboarding));
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei Firmensms'), findsOneWidget);

    await tester.tap(find.text('Überspringen'));
    await tester.pumpAndSettle();

    expect(find.text('Firmensms'), findsOneWidget);
    expect(await onboarding.isCompleted(), isTrue);
  });

  testWidgets('walks through the steps and stores credentials', (tester) async {
    final credentials = _MemoryCredentials();
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          credentials: credentials,
          onboarding: onboarding,
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Zugangsdaten'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Benutzername'),
      'anna',
    );
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Feld darf nicht leer sein'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort (Programmspezifisch)'),
      'geheim',
    );
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Gut zu wissen'), findsOneWidget);
    expect(credentials.username, 'anna');
    expect(credentials.password, 'geheim');

    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
    expect(await onboarding.isCompleted(), isTrue);
  });
}
