import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

/// Checks the server every 15s and shows a phone notification when the
/// admin updates an order (e.g. "Finished work").
/// v0.0.1 works while the app is open or in the background.
/// Next step for closed-app push: Firebase Cloud Messaging.
class Notifier {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final ValueNotifier<int> tick = ValueNotifier(0);
  static Timer? _timer;
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> start() async {
    await init();
    _timer?.cancel();
    await _poll();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _poll() async {
    if (Api.token == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'lastNotif_${Api.user?.id}';
      final stored = prefs.getInt(key);
      final list = await Api.notifications(stored ?? 0);
      if (list.isEmpty) {
        if (stored == null) await prefs.setInt(key, 0);
        return;
      }
      if (stored != null) {
        for (final n in list) {
          await _plugin.show(
            n['id'] as int,
            n['title'] as String,
            n['body'] as String,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                  'gamotin_orders', 'Order updates',
                  importance: Importance.max, priority: Priority.high),
            ),
          );
        }
        tick.value++;
      }
      await prefs.setInt(key, list.last['id'] as int);
    } catch (_) {/* try again next tick */}
  }
}
