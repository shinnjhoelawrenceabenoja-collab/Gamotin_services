import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'theme.dart';

/// First dashboard after loading: stylish landing with Login / Register.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Widget _chip(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(.12),
            borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, color: G.orange, size: 18),
          const SizedBox(width: 8),
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: G.gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.print_rounded,
                      size: 40, color: G.navy),
                ),
                const SizedBox(height: 24),
                const Text('Welcome to',
                    style: TextStyle(color: Colors.white70, fontSize: 18)),
                const Text('Gamotin\nServices',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        height: 1.05,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                const Text(
                    'Send your photos and documents, choose how you want them printed, and we notify you when they are ready.',
                    style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)),
                const SizedBox(height: 22),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip(Icons.photo_library_outlined, 'Photos & files'),
                  _chip(Icons.palette_outlined, 'Color or B&W'),
                  _chip(Icons.notifications_active_outlined, 'Pickup alerts'),
                ]),
                const Spacer(flex: 2),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: G.orange, foregroundColor: Colors.white),
                  onPressed: () => Navigator.push(
                      context, G.fade(const AuthPage(register: false))),
                  child: const Text('Login',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.push(
                      context, G.fade(const AuthPage(register: true))),
                  child: const Text('Create an account',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
