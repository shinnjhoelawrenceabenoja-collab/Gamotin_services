import 'package:flutter/material.dart';
import 'api.dart';
import 'dashboard_page.dart';
import 'theme.dart';
import 'welcome_page.dart';

/// Loading screen shown before login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final r = await Future.wait<Object>([
      Api.restore(),
      Future<Object>.delayed(const Duration(milliseconds: 2600), () => 0),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        G.fade(r[0] == true ? const DashboardPage() : const WelcomePage()));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: G.gradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Icon(Icons.print_rounded,
                      size: 72, color: Colors.white),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _c,
                child: const Column(children: [
                  Text('Gamotin Services',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5)),
                  SizedBox(height: 6),
                  Text('Print. Easy. Fast.',
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                ]),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  child: LinearProgressIndicator(
                      minHeight: 6,
                      color: G.orange,
                      backgroundColor: Colors.white24),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Loading...', style: TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      ),
    );
  }
}
