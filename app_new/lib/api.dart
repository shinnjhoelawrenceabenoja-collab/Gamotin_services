import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Server cannot be reached (no internet, server down, timeout, 5xx).
class OfflineException implements Exception {
  @override
  String toString() => 'Cannot reach the server. Check your connection and try again.';
}

/// Token rejected (logged out / expired).
class AuthException implements Exception {
  @override
  String toString() => 'Please log in again.';
}

/// Server answered with a real error (wrong password, bad request...).
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  // Build with: flutter build apk --dart-define=API_URL=https://your-server
  static const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://YOUR-SERVER');
  static String? token, name, phone;
  static bool online = true; // last known server state
  static const _t = Duration(seconds: 8);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
    name = p.getString('name');
    phone = p.getString('phone');
  }

  static Future<void> _save(Map j, String ph) async {
    token = j['token'];
    name = j['name'];
    phone = ph;
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token!);
    await p.setString('name', name!);
    await p.setString('phone', ph);
  }

  /// Logs out but KEEPS orders waiting in the outbox.
  static Future<void> logout() async {
    token = name = phone = null;
    final p = await SharedPreferences.getInstance();
    for (final k in ['token', 'name', 'phone', 'orders_cache']) {
      await p.remove(k);
    }
  }

  static Map<String, String> get _h => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic _parse(http.Response r) {
    if (r.statusCode >= 500) throw OfflineException();
    dynamic j;
    try {
      j = r.body.isEmpty ? {} : jsonDecode(r.body);
    } catch (_) {
      j = {};
    }
    if (r.statusCode == 401) throw AuthException();
    if (r.statusCode >= 400) {
      throw ApiException(j is Map && j['error'] != null ? '${j['error']}' : 'Error ${r.statusCode}');
    }
    return j;
  }

  static Future<T> _net<T>(Future<T> Function() f) async {
    try {
      final v = await f();
      online = true;
      return v;
    } on ApiException {
      online = true;
      rethrow;
    } on AuthException {
      online = true;
      rethrow;
    } on OfflineException {
      online = false;
      rethrow;
    } on Exception {
      online = false;
      throw OfflineException();
    }
  }

  /// Quick check (4 s) whether the server answers.
  static Future<bool> ping() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/')).timeout(const Duration(seconds: 4));
      online = r.statusCode < 500;
    } catch (_) {
      online = false;
    }
    return online;
  }

  static Future<void> login(String ph, String pw) => _net(() async {
        final r = await http
            .post(Uri.parse('$baseUrl/api/login'), headers: _h, body: jsonEncode({'phone': ph, 'password': pw}))
            .timeout(_t);
        await _save(_parse(r), ph);
      });

  static Future<void> register(String n, String ph, String email, String pw) => _net(() async {
        final r = await http
            .post(Uri.parse('$baseUrl/api/register'),
                headers: _h, body: jsonEncode({'name': n, 'phone': ph, 'email': email, 'password': pw}))
            .timeout(_t);
        await _save(_parse(r), ph);
      });

  /// Returns the server's orders, or the last saved copy when offline.
  static Future<List<Map<String, dynamic>>> myOrders() async {
    final p = await SharedPreferences.getInstance();
    try {
      final list = await _net(() async {
        final r = await http.get(Uri.parse('$baseUrl/api/orders/mine'), headers: _h).timeout(_t);
        final j = _parse(r);
        if (j is! List) throw OfflineException();
        return j.cast<Map<String, dynamic>>();
      });
      await p.setString('orders_cache', jsonEncode(list));
      return list;
    } on OfflineException {
      final raw = p.getString('orders_cache');
      return raw == null ? [] : (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    }
  }

  /// files: [{'path': ..., 'name': ...}]
  static Future<void> submitOrder(Map<String, String> fields, List<Map<String, String>> files) async {
    for (final f in files) {
      if (!File(f['path']!).existsSync()) {
        throw ApiException('A file was removed from this phone: ${f['name']}');
      }
    }
    await _net(() async {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/orders'))
        ..headers['Authorization'] = 'Bearer $token'
        ..fields.addAll(fields);
      for (final f in files) {
        req.files.add(await http.MultipartFile.fromPath('files', f['path']!, filename: f['name']));
      }
      final res = await http.Response.fromStream(await req.send().timeout(const Duration(minutes: 10)));
      _parse(res);
    });
  }
}
