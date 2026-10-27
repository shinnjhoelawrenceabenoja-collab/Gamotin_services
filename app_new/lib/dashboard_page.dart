import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'notifier.dart';
import 'orders_page.dart';
import 'outbox.dart';
import 'print_page.dart';
import 'theme.dart';
import 'welcome_page.dart';

class _Service {
  final String title;
  final IconData icon;
  final WidgetBuilder page;
  const _Service(this.title, this.icon, this.page);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Add future services here and they show up as tiles automatically.
  static final services = <_Service>[
    _Service('Printing', Icons.print_outlined, (_) => const PrintPage()),
    _Service('My Orders', Icons.receipt_long_outlined, (_) => const OrdersPage()),
  ];

  Timer? _timer;
  final Map<int, String> _last = {};
  List<Map<String, dynamic>> _orders = [];
  bool _first = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _queued = 0;

  // Every 15 s: send orders saved while offline, then refresh the order list.
  Future<void> _tick() async {
    await Outbox.flush();
    await _poll();
    final q = (await Outbox.mine()).length;
    if (mounted) setState(() => _queued = q);
  }

  // Notifies the customer when an order flips to "finished" (app open / in memory).
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
      if (mounted) setState(() => _orders = orders.take(3).toList());
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _open(WidgetBuilder b) => Navigator.push(context, MaterialPageRoute(builder: b)).then((_) => _tick());

  Future<void> _logout() async {
    await Api.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false);
  }

  void _profile() => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircleAvatar(radius: 30, backgroundColor: purple, child: Icon(Icons.person, color: Colors.white, size: 34)),
              const SizedBox(height: 12),
              Text(Api.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: pink, shape: const StadiumBorder(), minimumSize: const Size(200, 48)),
                  onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Logout')),
            ]),
          ),
        ),
      );

  Widget _tile(_Service s) => Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: Material(
            color: purpleDark, borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _open(s.page),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(s.icon, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );

  Widget _orderCard(Map<String, dynamic> o) {
    final done = o['status'] == 'finished';
    final color = o['color'] == 'color' ? 'Colored' : 'Black & White';
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Order #${o['id']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(color: done ? green : pink, borderRadius: BorderRadius.circular(99)),
            child: Text(done ? 'Finished' : 'Pending', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.schedule, color: purple), const SizedBox(width: 12),
          Text(done ? 'Ready for pickup' : 'Waiting to be printed', style: const TextStyle(color: grey, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.copy_outlined, color: purple), const SizedBox(width: 12),
          Expanded(child: Text('${o['copies']} copies · ${o['paper_size'].toString().split(' ').first} · $color',
              style: const TextStyle(color: grey, fontSize: 14), overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: purple,
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 28),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w300, fontFamily: 'Montserrat'),
                      children: [const TextSpan(text: 'Hello, '), TextSpan(text: Api.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700))],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Print your files today', style: TextStyle(color: soft, fontSize: 14)),
                  if (!Api.online || _queued > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: purpleDark, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Icon(Api.online ? Icons.cloud_upload_outlined : Icons.cloud_off_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          !Api.online
                              ? 'Offline mode${_queued > 0 ? ' – $_queued order(s) saved, will send automatically' : ' – showing saved data'}'
                              : 'Sending $_queued saved order(s)…',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Material(
                    color: purpleDark, borderRadius: BorderRadius.circular(34),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(34),
                      onTap: () => _open((_) => const PrintPage()),
                      child: Container(
                        height: 68, padding: const EdgeInsets.fromLTRB(28, 0, 10, 0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                          Text('Upload photos or files', style: TextStyle(color: Colors.white, fontSize: 14)),
                          CircleAvatar(radius: 24, backgroundColor: purple, child: Icon(Icons.upload_outlined, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text('Services', style: TextStyle(color: soft, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      i < services.length
                          ? _tile(services[i])
                          : Expanded(child: AspectRatio(aspectRatio: 1, child: Opacity(opacity: .6,
                              child: Container(decoration: BoxDecoration(color: purpleDark, borderRadius: BorderRadius.circular(22)),
                                  alignment: Alignment.center,
                                  child: const Text('Coming\nsoon', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)))))),
                    ],
                  ]),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
            Container(
              width: double.infinity, color: Colors.white,
              child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    height: 126,
                    child: _orders.isEmpty
                        ? const Center(child: Text('No orders yet. Tap + to print.', style: TextStyle(color: grey)))
                        : PageView.builder(
                            itemCount: _orders.length,
                            onPageChanged: (i) => setState(() => _page = i),
                            itemBuilder: (_, i) => _orderCard(_orders[i])),
                  ),
                  if (_orders.length > 1)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (var i = 0; i < _orders.length; i++)
                        Container(
                          width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: i == _page ? purple : Colors.transparent,
                              border: Border.all(color: purple, width: 2)),
                        ),
                    ]),
                  Container(
                    height: 78, margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFCFD6DD), width: 2))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      IconButton(tooltip: 'Home', icon: const Icon(Icons.home_rounded, color: Color(0xFF9AA5B1), size: 28), onPressed: () {}),
                      IconButton(tooltip: 'My orders', icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF9AA5B1), size: 28),
                          onPressed: () => _open((_) => const OrdersPage())),
                      FloatingActionButton(
                          heroTag: 'new', backgroundColor: pink, foregroundColor: Colors.white, elevation: 0, shape: const CircleBorder(),
                          onPressed: () => _open((_) => const PrintPage()), child: const Icon(Icons.add, size: 30)),
                      IconButton(tooltip: 'Notifications', icon: const Icon(Icons.notifications_none, color: Color(0xFF9AA5B1), size: 28),
                          onPressed: () => _open((_) => const OrdersPage())),
                      IconButton(tooltip: 'Profile', icon: const Icon(Icons.person_outline, color: Color(0xFF9AA5B1), size: 28), onPressed: _profile),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
}
