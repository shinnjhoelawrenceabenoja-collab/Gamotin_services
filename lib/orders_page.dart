import 'package:flutter/material.dart';
import 'api.dart';
import 'models.dart';
import 'notifier.dart';
import 'theme.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order>? _orders;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    Notifier.tick.addListener(_load); // refresh when a notification arrives
  }

  @override
  void dispose() {
    Notifier.tick.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final o = await Api.myOrders();
      if (mounted) setState(() { _orders = o; _error = null; });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  static Color _col(String s) => switch (s) {
        'finished' => Colors.green,
        'printing' => G.orange,
        'cancelled' => Colors.red,
        _ => Colors.blueGrey,
      };

  static String _label(String s) => switch (s) {
        'finished' => 'Finished - ready for pickup',
        'printing' => 'Printing',
        'cancelled' => 'Cancelled',
        _ => 'Waiting',
      };

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _detail(Order o) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order #${o.id}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('${o.copies} copies - ${o.color ? 'Colored' : 'Black & White'}'),
          Text('${o.paperSize} - ${o.paperType}'),
          Text(o.duplex ? 'Back to back' : 'One side'),
          if (o.pageRange.isNotEmpty) Text('Pages: ${o.pageRange}'),
          if (o.notes.isNotEmpty) Text('Notes: ${o.notes}'),
          const SizedBox(height: 8),
          Text('Files: ${o.files.map((f) => f.filename).join(', ')}',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 18),
          if (o.status == 'pending')
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel order'),
              onPressed: () async {
                Navigator.pop(c);
                try {
                  await Api.cancelOrder(o.id);
                  _load();
                } on ApiException catch (e) {
                  if (mounted) G.snack(context, e.message);
                }
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null && _orders == null) {
      body = Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!), const SizedBox(height: 8),
        FilledButton.tonal(onPressed: _load, child: const Text('Retry')),
      ]));
    } else if (_orders == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_orders!.isEmpty) {
      body = const Center(child: Text('No orders yet. Tap Print to start.'));
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders!.length,
        itemBuilder: (_, i) {
          final o = _orders![i];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              onTap: () => _detail(o),
              contentPadding: const EdgeInsets.all(14),
              title: Text('Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${o.files.length} file(s) - ${o.copies} copies - ${o.paperSize}\n${_date(o.createdAt)}'),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _col(o.status).withOpacity(.14),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_label(o.status).split(' - ').first,
                    style: TextStyle(color: _col(o.status), fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders'), backgroundColor: G.bg),
      body: RefreshIndicator(onRefresh: _load, child: body),
    );
  }
}
