import 'package:flutter/material.dart';
import 'api.dart';
import 'theme.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Map<String, dynamic>>> _f = Api.myOrders();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: purple,
        appBar: AppBar(
          backgroundColor: purple, foregroundColor: Colors.white, elevation: 0,
          title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() => _f = Api.myOrders());
            await _f;
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _f,
            builder: (c, s) {
              if (s.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (s.hasError) {
                return ListView(children: [Padding(padding: const EdgeInsets.all(30),
                    child: Text(s.error.toString().replaceFirst('Exception: ', ''), style: const TextStyle(color: Colors.white)))]);
              }
              final l = s.data!;
              if (l.isEmpty) {
                return ListView(children: const [Padding(padding: EdgeInsets.all(50),
                    child: Center(child: Text('No orders yet.', style: TextStyle(color: Colors.white))))]);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: l.length,
                itemBuilder: (c, i) {
                  final o = l[i];
                  final done = o['status'] == 'finished';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Order #${o['id']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(color: done ? green : pink, borderRadius: BorderRadius.circular(99)),
                          child: Text(done ? 'Finished' : 'Pending', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text('${(o['files'] as List).length} file(s) · ${o['copies']} copies · '
                          '${o['color'] == 'color' ? 'Colored' : 'B&W'}${o['duplex'] == true ? ' · Back to back' : ''}',
                          style: const TextStyle(color: grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('${o['paper_size']} · ${o['paper_type']}', style: const TextStyle(color: grey, fontSize: 13)),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      );
}
