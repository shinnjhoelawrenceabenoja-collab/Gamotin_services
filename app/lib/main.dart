import 'package:flutter/material.dart';
import 'api.dart';
import 'notifier.dart';
import 'splash_page.dart';
import 'theme.dart';

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
        theme: buildTheme(),
        home: const SplashPage(),
      );
}
