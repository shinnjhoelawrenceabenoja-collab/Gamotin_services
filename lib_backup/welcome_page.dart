import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'theme.dart';
import 'widgets.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Widget _chip(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: purpleDark, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  void _go(BuildContext c, bool register) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => AuthPage(register: register)));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: purple,
        body: Column(children: [
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: const [
                    LogoCircle(48), SizedBox(width: 12),
                    Text('GAMOTIN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ]),
                  const SizedBox(height: 70),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white, fontSize: 38, height: 1.15, fontWeight: FontWeight.w300, fontFamily: 'Montserrat'),
                      children: [TextSpan(text: 'Print '), TextSpan(text: 'anything,', style: TextStyle(fontWeight: FontWeight.w800)), TextSpan(text: '\nanytime.')],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Send your photos and documents from your phone. We print them and tell you when they are ready.',
                      style: TextStyle(color: soft, fontSize: 14, height: 1.6)),
                  const SizedBox(height: 22),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip(Icons.image_outlined, 'Photos'),
                    _chip(Icons.description_outlined, 'Documents'),
                    _chip(Icons.notifications_none, 'Ready alerts'),
                  ]),
                ]),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(36, 36, 36, 28),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(44))),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Welcome', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Sign in or create an account to start', style: TextStyle(fontSize: 13, color: grey)),
                const SizedBox(height: 20),
                BigButton('Login', onPressed: () => _go(context, false)),
                const SizedBox(height: 12),
                BigButton('Register', outlined: true, onPressed: () => _go(context, true)),
              ]),
            ),
          ),
        ]),
      );
}
