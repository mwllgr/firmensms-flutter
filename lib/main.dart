import 'package:firmensms/pages/compose.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SmsApp());
}

class SmsApp extends StatelessWidget {
  const SmsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firmensms',
      theme: ThemeData(
          primaryTextTheme:
              const TextTheme(headline6: TextStyle(color: Colors.white))),
      home: const ComposePage(),
    );
  }
}
