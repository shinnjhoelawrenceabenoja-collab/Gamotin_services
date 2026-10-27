import 'package:flutter/material.dart';
import 'api.dart';
import 'auth_page.dart';
import 'dashboard_page.dart';
import 'notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.load();
  await initNotifier();
  runApp(const GamotinApp());
}

class GamotinApp extends StatelessWidget {
  const GamotinApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Gamotin Services',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorSchemeSeed: const Color(0xFF0F6CBD), useMaterial3: true),
        darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF0F6CBD),
            brightness: Brightness.dark,
            useMaterial3: true),
        home: Api.token == null ? const AuthPage() : const DashboardPage(),
      );
}
