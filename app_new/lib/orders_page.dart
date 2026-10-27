import 'package:flutter/material.dart';
import 'api.dart';
import 'outbox.dart';
import 'theme.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<dynamic>> _f = _load();

  Future<List<dynamic>> _load() async {
    await Outbox.flush();
    return [await Outbox.mine(), await Api.myOrders()];
  }

  void _reload() => setState(() => _f = _load());

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: child,
      );

  Widget _queued(Map<String, dynamic> o) {
    final f = Map<String, String>.from(o['fields']);
    final err = o['error'] as String?;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Saved on phone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        _tag(err == null ? 'Waiting to send' : 'Not accepted', err == null ? purpleDark : pink),
      ]),
      const SizedBox(height: 10),
      Text('${(o['files'] as List).length} file(s) · ${f['copies']} copies · ${f['color'] == 'color' ? 'Colored' : 'B&W'}'
          '${f['duplex'] == 'true' ? ' · Back to back' : ''}', style: const TextStyle(color: grey, fontSize: 13)),
      Text('${f['paper_size']} · ${f['paper_type']}', style: const TextStyle(color: grey, fontSize: 13)),
      if (err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(err, style: const TextStyle(color: pink, fontSize: 12))),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (err != null) TextButton(onPressed: () async { await Outbox.retry(o['id']); _reload(); }, child: const Text('Retry')),
        TextButton(onPressed: () async { await Outbox.remove(o['id']); _reload(); }, child: const Text('Delete')),
      ]),
    ]));
  }

  Widget _server(Map<String, dynamic> o) {
    final done = o['status'] == 'finished';
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Order #${o['id']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        _tag(done ? 'Finished' : 'Pending', done ? green : pink),
      ]),
      const SizedBox(height: 10),
      Text('${(o['files'] as List).length} file(s) · ${o['copies']} copies · '
          '${o['color'] == 'color' ? 'Colored' : 'B&W'}${o['duplex'] == true ? ' · Back to back' : ''}',
          style: const TextStyle(color: grey, fontSize: 13)),
      const SizedBox(height: 4),
      Text('${o['paper_size']} · ${o['paper_type']}', style: const TextStyle(color: grey, fontSize: 13)),
    ]));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: purple,
        appBar: AppBar(
          backgroundColor: purple, foregroundColor: Colors.white, elevation: 0,
          title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: RefreshIndicator(
          onRefresh: () async { _reload(); await _f; },
          child: FutureBuilder<List<dynamic>>(
            future: _f,
            builder: (c, s) {
              if (s.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (s.hasError) {
                return ListView(children: [Padding(padding: const EdgeInsets.all(30),
                    child: Text(s.error.toString(), style: const TextStyle(color: Colors.white)))]);
              }
              final queued = (s.data![0] as List).cast<Map<String, dynamic>>();
              final server = (s.data![1] as List).cast<Map<String, dynamic>>();
              if (queued.isEmpty && server.isEmpty) {
                return ListView(children: const [Padding(padding: EdgeInsets.all(50),
                    child: Center(child: Text('No orders yet.', style: TextStyle(color: Colors.white))))]);
              }
              return ListView(padding: const EdgeInsets.all(16), children: [
                if (!Api.online)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Offline – showing the last saved list. Pull down to retry.',
                        style: TextStyle(color: soft, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                for (final o in queued) _queued(o),
                for (final o in server) _server(o),
              ]);
            },
          ),
        ),
      );
}
