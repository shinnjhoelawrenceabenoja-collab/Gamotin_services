import 'package:flutter/material.dart';
import 'api.dart';
import 'notifier.dart';
import 'orders_page.dart';
import 'print_page.dart';
import 'theme.dart';
import 'welcome_page.dart';

/// Home: pick which service screen to open.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    Notifier.start();
  }

  Future<void> _logout() async {
    Notifier.stop();
    await Api.logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(G.fade(const WelcomePage()), (_) => false);
  }

  Widget _tile(String title, String sub, IconData icon, Color color,
      VoidCallback? onTap) {
    final off = onTap == null;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap ?? () => G.snack(context, '$title is coming soon'),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: (off ? Colors.grey : color).withOpacity(.14),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: off ? Colors.grey : color, size: 28),
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: off ? Colors.grey : G.navy)),
          const SizedBox(height: 2),
          Text(off ? 'Coming soon' : sub,
              style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = Api.user;
    return Scaffold(
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 14, 12, 28),
          decoration: const BoxDecoration(
            gradient: G.gradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Hello,', style: TextStyle(color: Colors.white70, fontSize: 15)),
                Text(u?.name ?? 'Guest',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('What would you like to do today?',
                    style: TextStyle(color: Colors.white70)),
              ]),
            ),
            IconButton(
                tooltip: 'Logout',
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white)),
          ]),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: .95,
            children: [
              _tile('Print', 'Send photos & files', Icons.print_rounded, G.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrintPage()))),
              _tile('My Orders', 'Track your prints', Icons.receipt_long_rounded, G.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage()))),
              _tile('Scan & Copy', '', Icons.document_scanner_rounded, Colors.indigo, null),
              _tile('Lamination', '', Icons.layers_rounded, Colors.purple, null),
            ],
          ),
        ),
      ]),
    );
  }
}
