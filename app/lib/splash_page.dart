import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'dashboard_page.dart';
import 'theme.dart';
import 'welcome_page.dart';
import 'widgets.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      // Already logged in -> dashboard, otherwise the Welcome (Login / Register) screen.
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => Api.token == null ? const WelcomePage() : const DashboardPage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: purple,
        body: Stack(alignment: Alignment.center, children: [
          const Positioned.fill(child: Center(child: Opacity(opacity: .5, child: Ring(640)))),
          const Center(child: Ring(520)),
          const Center(child: Ring(380)),
          Column(mainAxisSize: MainAxisSize.min, children: const [
            LogoCircle(120),
            SizedBox(height: 24),
            Text('GAMOTIN', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 2)),
            SizedBox(height: 6),
            Text('SERVICES', style: TextStyle(color: soft, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 6)),
          ]),
          Positioned(
            left: 80, right: 80, bottom: 110,
            child: Column(children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 2300),
                builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: purpleDark, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              const Text('Loading…', style: TextStyle(color: soft, fontSize: 13)),
            ]),
          ),
          const Positioned(bottom: 36, child: Text('Version 0.0.1', style: TextStyle(color: soft, fontSize: 12))),
        ]),
      );
}
