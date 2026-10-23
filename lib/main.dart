import 'package:flutter/material.dart';
import 'splash_page.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GamotinApp());
}

class GamotinApp extends StatelessWidget {
  const GamotinApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Gamotin Services',
        debugShowCheckedModeBanner: false,
        theme: G.theme(),
        home: const SplashPage(),
      );
}
