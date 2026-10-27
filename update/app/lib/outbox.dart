import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

/// Orders are ALWAYS saved on the phone first, then uploaded when the server is reachable.
class Outbox {
  static const _key = 'outbox';
  static bool _busy = false;

  static Future<List<Map<String, dynamic>>> _all() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    return raw == null ? [] : (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> _save(List<Map<String, dynamic>> l) async =>
      (await SharedPreferences.getInstance()).setString(_key, jsonEncode(l));

  /// Waiting orders that belong to the logged-in user.
  static Future<List<Map<String, dynamic>>> mine() async =>
      (await _all()).where((o) => o['owner'] == Api.phone).toList();

  /// Copies the files into app storage and queues the order. Returns its local id.
  static Future<String> add(Map<String, String> fields, List<PlatformFile> files) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}';
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/outbox/$id')..createSync(recursive: true);
    final saved = <Map<String, String>>[];
    for (final f in files) {
      final dest = '${dir.path}/${saved.length}_${f.name}';
      await File(f.path!).copy(dest);
      saved.add({'path': dest, 'name': f.name, 'size': '${f.size}'});
    }
    final l = await _all();
    l.add({'id': id, 'owner': Api.phone, 'fields': fields, 'files': saved, 'created': DateTime.now().toIso8601String(), 'error': null});
    await _save(l);
    return id;
  }

  static void _deleteFiles(Map<String, dynamic> o) {
    try {
      final files = o['files'] as List;
      if (files.isNotEmpty) Directory(File(files.first['path']).parent.path).deleteSync(recursive: true);
    } catch (_) {}
  }

  /// Uploads waiting orders. Stops quietly if the server is unreachable. Returns how many were sent.
  static Future<int> flush() async {
    if (_busy || Api.token == null) return 0;
    _busy = true;
    var sent = 0;
    try {
      if ((await mine()).where((o) => o['error'] == null).isEmpty) return 0;
      if (!await Api.ping()) return 0;
      final l = await _all();
      for (final o in List<Map<String, dynamic>>.of(l)) {
        if (o['owner'] != Api.phone || o['error'] != null) continue;
        try {
          await Api.submitOrder(
            {...Map<String, String>.from(o['fields']), 'client_id': o['id']},
            (o['files'] as List).map((e) => Map<String, String>.from(e)).toList(),
          );
          l.removeWhere((x) => x['id'] == o['id']);
          _deleteFiles(o);
          sent++;
          await _save(l);
        } on OfflineException {
          break;
        } on AuthException {
          break;
        } on ApiException catch (e) {
          o['error'] = e.message;
          await _save(l);
        }
      }
    } finally {
      _busy = false;
    }
    return sent;
  }

  static Future<void> remove(String id) async {
    final l = await _all();
    for (final o in l.where((x) => x['id'] == id)) {
      _deleteFiles(o);
    }
    l.removeWhere((x) => x['id'] == id);
    await _save(l);
  }

  static Future<void> retry(String id) async {
    final l = await _all();
    for (final o in l.where((x) => x['id'] == id)) {
      o['error'] = null;
    }
    await _save(l);
    await flush();
  }
}
