import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'auth_page.dart';
import 'notifier.dart';
import 'orders_page.dart';
import 'print_page.dart';

class _Service {
  final String title, subtitle;
  final IconData icon;
  final WidgetBuilder page;
  const _Service(this.title, this.subtitle, this.icon, this.page);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Add future services to this list and they appear on the dashboard automatically.
  static final services = <_Service>[
    _Service('Printing', 'Upload files & photos to print', Icons.print_rounded, (_) => const PrintPage()),
    _Service('My Orders', 'Track your print orders', Icons.receipt_long_rounded, (_) => const OrdersPage()),
  ];

  Timer? _timer;
  final Map<int, String> _last = {};
  bool _first = true;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  // Notifies the customer when an order flips to "finished".
  // Works while the app is open/in memory. Closed-app push needs FCM (planned for 0.0.2).
  Future<void> _poll() async {
    try {
      final orders = await Api.myOrders();
      for (final o in orders) {
        final id = o['id'] as int, st = o['status'] as String;
        if (!_first && _last[id] != null && _last[id] != 'finished' && st == 'finished') {
          notify('Your print is ready!', 'Order #$id is finished. You can pick it up.');
        }
        _last[id] = st;
      }
      _first = false;
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Gamotin Services'),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Api.logout();
                if (!context.mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
              },
            ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Hello, ${Api.name ?? ''}!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('What do you need today?'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1,
            children: [
              for (final s in services)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: s.page)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(s.icon, size: 48, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 10),
                        Text(s.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(s.subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ]),
      );
}
