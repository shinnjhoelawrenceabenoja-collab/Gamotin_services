import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  final int? code;
  ApiException(this.message, [this.code]);
  @override
  String toString() => message;
}

class Api {
  static String? token;
  static User? user;

  static Map<String, String> get _h => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<dynamic> _run(Future<http.Response> Function() call) async {
    try {
      final r = await call().timeout(const Duration(seconds: 30));
      final body = r.body.isEmpty ? {} : jsonDecode(r.body);
      if (r.statusCode >= 400) {
        throw ApiException(
            (body is Map ? body['error'] : null) ?? 'Error ${r.statusCode}',
            r.statusCode);
      }
      return body;
    } on SocketException {
      throw ApiException('No internet connection. Please try again.');
    } on http.ClientException {
      throw ApiException('Cannot reach the server.');
    } on FormatException {
      throw ApiException('Unexpected server response.');
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error. Please try again.');
    }
  }

  static Uri _u(String p, [Map<String, String>? q]) =>
      Uri.parse('$kBaseUrl$p').replace(queryParameters: q);

  // ---- session ----
  static Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    if (token == null) {
      await p.remove('token');
      await p.remove('user');
    } else {
      await p.setString('token', token!);
      await p.setString('user', jsonEncode(user!.toJson()));
    }
  }

  static void _setSession(Map<String, dynamic> j) {
    token = j['token'];
    user = User.fromJson(j['user']);
  }

  /// Called by the splash screen. True = already logged in.
  static Future<bool> restore() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
    final u = p.getString('user');
    if (token == null || u == null) return false;
    user = User.fromJson(jsonDecode(u));
    try {
      final j = await _run(() => http.get(_u('/api/me'), headers: _h));
      user = User.fromJson(j['user']);
      await _save();
    } on ApiException catch (e) {
      if (e.code == 401) {
        await logout();
        return false;
      }
      // offline/server down: keep cached login
    }
    return true;
  }

  static Future<void> login(String email, String password) async {
    final j = await _run(() => http.post(_u('/api/login'),
        headers: _h, body: jsonEncode({'email': email, 'password': password})));
    _setSession(j);
    await _save();
  }

  static Future<void> register(
      String name, String phone, String email, String password) async {
    final j = await _run(() => http.post(_u('/api/register'),
        headers: _h,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'password': password
        })));
    _setSession(j);
    await _save();
  }

  static Future<void> logout() async {
    token = null;
    user = null;
    await _save();
  }

  // ---- orders ----
  static Future<int> createOrder({
    required List<PlatformFile> files,
    required int copies,
    required bool color,
    required String paperSize,
    required String paperType,
    required bool duplex,
    required String pageRange,
    required String notes,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _u('/api/orders'));
      req.headers['Authorization'] = 'Bearer $token';
      req.fields.addAll({
        'copies': '$copies',
        'color': '$color',
        'paper_size': paperSize,
        'paper_type': paperType,
        'duplex': '$duplex',
        'page_range': pageRange,
        'notes': notes,
      });
      for (final f in files) {
        req.files.add(await http.MultipartFile.fromPath('files', f.path!,
            filename: f.name));
      }
      final streamed = await req.send().timeout(const Duration(minutes: 5));
      final r = await http.Response.fromStream(streamed);
      final body = jsonDecode(r.body);
      if (r.statusCode >= 400) {
        throw ApiException(body['error'] ?? 'Upload failed', r.statusCode);
      }
      return body['id'];
    } on SocketException {
      throw ApiException('No internet connection. Please try again.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Upload failed. Check your connection and retry.');
    }
  }

  static Future<List<Order>> myOrders() async {
    final j = await _run(() => http.get(_u('/api/orders'), headers: _h));
    return (j['orders'] as List).map((e) => Order.fromJson(e)).toList();
  }

  static Future<void> cancelOrder(int id) => _run(
      () => http.post(_u('/api/orders/$id/cancel'), headers: _h));

  static Future<List<Map<String, dynamic>>> notifications(int after) async {
    final j = await _run(() =>
        http.get(_u('/api/notifications', {'after': '$after'}), headers: _h));
    return (j['notifications'] as List).cast<Map<String, dynamic>>();
  }
}
