import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  // Build with: flutter build apk --dart-define=API_URL=https://your-server.com
  static const baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'https://YOUR-SERVER');
  static String? token, name;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
    name = p.getString('name');
  }

  static Future<void> _save(Map j) async {
    token = j['token'];
    name = j['name'];
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token!);
    await p.setString('name', name!);
  }

  static Future<void> logout() async {
    token = name = null;
    await (await SharedPreferences.getInstance()).clear();
  }

  static Map<String, String> get _h => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic _parse(http.Response r) {
    final j = r.body.isEmpty ? {} : jsonDecode(r.body);
    if (r.statusCode >= 400) {
      throw Exception(j is Map && j['error'] != null ? j['error'] : 'Error ${r.statusCode}');
    }
    return j;
  }

  static Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f().timeout(const Duration(minutes: 5));
    } on Exception catch (e) {
      final m = e.toString().replaceFirst('Exception: ', '');
      if (m.contains('SocketException') || m.contains('ClientException') || m.contains('Timeout')) {
        throw Exception('No internet connection. Please try again.');
      }
      throw Exception(m);
    }
  }

  static Future<void> login(String phone, String pw) => _guard(() async {
        final r = await http.post(Uri.parse('$baseUrl/api/login'),
            headers: _h, body: jsonEncode({'phone': phone, 'password': pw}));
        await _save(_parse(r));
      });

  static Future<void> register(String n, String phone, String email, String pw) =>
      _guard(() async {
        final r = await http.post(Uri.parse('$baseUrl/api/register'),
            headers: _h,
            body: jsonEncode({'name': n, 'phone': phone, 'email': email, 'password': pw}));
        await _save(_parse(r));
      });

  static Future<List<Map<String, dynamic>>> myOrders() => _guard(() async {
        final r = await http.get(Uri.parse('$baseUrl/api/orders/mine'), headers: _h);
        return (_parse(r) as List).cast<Map<String, dynamic>>();
      });

  static Future<void> submitOrder(Map<String, String> fields, List<PlatformFile> files) =>
      _guard(() async {
        final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/orders'))
          ..headers['Authorization'] = 'Bearer $token'
          ..fields.addAll(fields);
        for (final f in files) {
          req.files.add(await http.MultipartFile.fromPath('files', f.path!, filename: f.name));
        }
        _parse(await http.Response.fromStream(await req.send()));
      });
}
