import 'package:flutter/material.dart';
import 'api.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Map<String, dynamic>>> _f = Api.myOrders();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() => _f = Api.myOrders());
            await _f;
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _f,
            builder: (c, s) {
              if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
              if (s.hasError) {
                return ListView(children: [Padding(padding: const EdgeInsets.all(24),
                    child: Text(s.error.toString().replaceFirst('Exception: ', '')))]);
              }
              final l = s.data!;
              if (l.isEmpty) return ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No orders yet.')))]);
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: l.length,
                itemBuilder: (c, i) {
                  final o = l[i];
                  final done = o['status'] == 'finished';
                  return Card(
                    child: ListTile(
                      leading: Icon(done ? Icons.check_circle : Icons.hourglass_top, color: done ? Colors.green : Colors.orange),
                      title: Text('Order #${o['id']} · ${done ? 'Finished' : 'Pending'}'),
                      subtitle: Text('${(o['files'] as List).length} file(s) · ${o['copies']} copies · '
                          '${o['color'] == 'color' ? 'Colored' : 'B&W'} · ${o['paper_size']} · ${o['paper_type']}'
                          '${o['duplex'] == true ? ' · Back to back' : ''}'),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}
