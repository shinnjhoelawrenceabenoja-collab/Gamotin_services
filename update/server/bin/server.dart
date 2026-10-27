import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

final env = Platform.environment;
late Connection db;
final _rng = Random.secure();

String rand(int n) => base64Url
    .encode(List.generate(n, (_) => _rng.nextInt(256)))
    .replaceAll(RegExp(r'[^A-Za-z0-9]'), 'x');
String hashPw(String salt, String pw) =>
    sha256.convert(utf8.encode('$salt:$pw')).toString();

Map<String, dynamic> row(ResultRow r) => r.toColumnMap().map(
    (k, v) => MapEntry(k, v is DateTime ? v.toIso8601String() : v));
Response jsonRes(Object o, [int code = 200]) => Response(code,
    body: jsonEncode(o), headers: {'content-type': 'application/json'});
Response err(String m, [int code = 400]) => jsonRes({'error': m}, code);

Future<Map<String, dynamic>?> authUser(Request r) async {
  var t = (r.headers['authorization'] ?? '').replaceFirst('Bearer ', '');
  if (t.isEmpty) t = r.url.queryParameters['token'] ?? '';
  if (t.isEmpty) return null;
  final res = await db.execute(
      Sql.named('SELECT u.id,u.name,u.role FROM sessions s '
          'JOIN users u ON u.id=s.user_id WHERE s.token=@t'),
      parameters: {'t': t});
  return res.isEmpty ? null : row(res.first);
}

Future<Response> startSession(int id, String name, String role) async {
  final token = rand(40);
  await db.execute(
      Sql.named('INSERT INTO sessions(token,user_id) VALUES(@t,@u)'),
      parameters: {'t': token, 'u': id});
  return jsonRes({'token': token, 'name': name, 'role': role});
}

Future<Response> register(Request r) async {
  final b = jsonDecode(await r.readAsString()) as Map;
  final name = '${b['name'] ?? ''}'.trim();
  final phone = '${b['phone'] ?? ''}'.trim();
  final email = '${b['email'] ?? ''}'.trim();
  final pw = '${b['password'] ?? ''}';
  if (name.isEmpty || phone.isEmpty || pw.length < 6) {
    return err('Name, phone and a password of 6+ characters are required');
  }
  final salt = rand(12);
  try {
    final res = await db.execute(
        Sql.named('INSERT INTO users(name,phone,email,salt,password_hash) '
            'VALUES(@n,@p,@e,@s,@h) RETURNING id'),
        parameters: {
          'n': name, 'p': phone, 'e': email, 's': salt, 'h': hashPw(salt, pw)
        });
    return startSession(res.first[0] as int, name, 'client');
  } on ServerException catch (e) {
    if (e.code == '23505') return err('That phone number is already registered', 409);
    rethrow;
  }
}

Future<Response> login(Request r) async {
  final b = jsonDecode(await r.readAsString()) as Map;
  final res = await db.execute(
      Sql.named('SELECT id,name,role,salt,password_hash FROM users WHERE phone=@p'),
      parameters: {'p': '${b['phone'] ?? ''}'.trim()});
  if (res.isEmpty) return err('Wrong phone or password', 401);
  final u = row(res.first);
  if (hashPw(u['salt'], '${b['password'] ?? ''}') != u['password_hash']) {
    return err('Wrong phone or password', 401);
  }
  return startSession(u['id'], u['name'], u['role']);
}

const _orderSelect = '''
SELECT o.*, u.name AS user_name, u.phone AS user_phone, u.email AS user_email,
 COALESCE((SELECT json_agg(json_build_object('id',f.id,'name',f.original_name,'size',f.size) ORDER BY f.id)
           FROM order_files f WHERE f.order_id=o.id),'[]'::json)::text AS files
FROM orders o JOIN users u ON u.id=o.user_id
''';

Future<Response> listOrders(Request r, {required bool admin}) async {
  final u = await authUser(r);
  if (u == null) return err('Login required', 401);
  if (admin && u['role'] != 'admin') return err('Admins only', 403);
  final res = await db.execute(
      Sql.named('$_orderSelect ${admin ? '' : 'WHERE o.user_id=@u'} '
          'ORDER BY o.id DESC LIMIT 300'),
      parameters: admin ? {} : {'u': u['id']});
  return jsonRes(res.map((x) {
    final m = row(x);
    m['files'] = jsonDecode(m['files']);
    return m;
  }).toList());
}

Future<Response> createOrder(Request r) async {
  final u = await authUser(r);
  if (u == null) return err('Login required', 401);
  final mp = r.multipart();
  if (mp == null) return err('Expected multipart form');
  Directory('uploads').createSync(recursive: true);
  final f = <String, String>{};
  final saved = <Map<String, dynamic>>[];
  await for (final part in mp.parts) {
    final cd = part.headers['content-disposition'] ?? '';
    final name = RegExp(r'(?:^|[;\s])name="([^"]*)"').firstMatch(cd)?.group(1) ?? '';
    final fn = RegExp(r'filename="([^"]*)"').firstMatch(cd)?.group(1);
    if (fn == null) {
      f[name] = await part.readString();
    } else {
      final ext = fn.contains('.') ? '.${fn.split('.').last.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}' : '';
      final stored = '${rand(14)}$ext';
      final sink = File('uploads/$stored').openWrite();
      await sink.addStream(part);
      await sink.close();
      saved.add({'o': fn, 's': stored, 'z': File('uploads/$stored').lengthSync()});
    }
  }
  if (saved.isEmpty) return err('Add at least one file or photo');
  // Offline retries send the same client_id: never create the order twice.
  final cid = (f['client_id'] ?? '').trim();
  if (cid.isNotEmpty) {
    final ex = await db.execute(
        Sql.named('SELECT id FROM orders WHERE user_id=@u AND client_id=@c'),
        parameters: {'u': u['id'], 'c': cid});
    if (ex.isNotEmpty) {
      for (final s in saved) {
        try { File('uploads/${s['s']}').deleteSync(); } catch (_) {}
      }
      return jsonRes({'id': ex.first[0], 'duplicate': true});
    }
  }
  final id = await db.runTx((tx) async {
    final res = await tx.execute(
        Sql.named('INSERT INTO orders(user_id,copies,color,paper_size,paper_type,duplex,page_range,notes,client_id) '
            'VALUES(@u,@c,@col,@ps,@pt,@d,@pr,@n,@cid) RETURNING id'),
        parameters: {
          'u': u['id'],
          'c': (int.tryParse(f['copies'] ?? '1') ?? 1).clamp(1, 9999),
          'col': f['color'] == 'color' ? 'color' : 'bw',
          'ps': f['paper_size'] ?? 'A4',
          'pt': f['paper_type'] ?? 'Plain Bond',
          'd': f['duplex'] == 'true',
          'pr': (f['page_range'] ?? '').trim(),
          'n': (f['notes'] ?? '').trim(),
          'cid': cid.isEmpty ? null : cid,
        });
    final oid = res.first[0] as int;
    for (final s in saved) {
      await tx.execute(
          Sql.named('INSERT INTO order_files(order_id,original_name,stored_name,size) VALUES(@o,@n,@s,@z)'),
          parameters: {'o': oid, 'n': s['o'], 's': s['s'], 'z': s['z']});
    }
    return oid;
  });
  return jsonRes({'id': id}, 201);
}

Future<Response> download(Request r, String oid, String fid) async {
  final u = await authUser(r);
  if (u == null) return err('Login required', 401);
  final res = await db.execute(
      Sql.named('SELECT f.original_name,f.stored_name,o.user_id FROM order_files f '
          'JOIN orders o ON o.id=f.order_id WHERE f.id=@f AND o.id=@o'),
      parameters: {'f': int.tryParse(fid) ?? 0, 'o': int.tryParse(oid) ?? 0});
  if (res.isEmpty) return err('Not found', 404);
  final x = row(res.first);
  if (u['role'] != 'admin' && x['user_id'] != u['id']) return err('Forbidden', 403);
  final file = File('uploads/${x['stored_name']}');
  if (!file.existsSync()) return err('File missing on server', 404);
  return Response.ok(file.openRead(), headers: {
    'content-type': 'application/octet-stream',
    'content-disposition':
        'attachment; filename="${'${x['original_name']}'.replaceAll('"', '')}"',
  });
}

Future<Response> finish(Request r, String oid) async {
  final u = await authUser(r);
  if (u == null || u['role'] != 'admin') return err('Admins only', 403);
  await db.execute(
      Sql.named("UPDATE orders SET status='finished', finished_at=now() WHERE id=@o"),
      parameters: {'o': int.tryParse(oid) ?? 0});
  return jsonRes({'ok': true});
}

Future<void> main() async {
  db = await Connection.open(
    Endpoint(
      host: env['DB_HOST'] ?? 'localhost',
      port: int.tryParse(env['DB_PORT'] ?? '') ?? 5432,
      database: env['DB_NAME'] ?? 'gamotin',
      username: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASS'],
    ),
    settings: ConnectionSettings(
        sslMode: env['DB_SSL'] == 'true' ? SslMode.require : SslMode.disable),
  );
  await db.execute(File('schema.sql').readAsStringSync(),
      queryMode: QueryMode.simple);

  // Create/refresh YOUR admin account from environment variables.
  final ap = env['ADMIN_PHONE'], apw = env['ADMIN_PASSWORD'];
  if (ap != null && apw != null) {
    final salt = rand(12);
    await db.execute(
        Sql.named("INSERT INTO users(name,phone,email,salt,password_hash,role) "
            "VALUES(@n,@p,'',@s,@h,'admin') ON CONFLICT (phone) DO UPDATE "
            "SET role='admin', salt=@s, password_hash=@h"),
        parameters: {
          'n': env['ADMIN_NAME'] ?? 'Gamotin Admin', 'p': ap, 's': salt,
          'h': hashPw(salt, apw)
        });
  }

  final router = Router()
    ..post('/api/register', register)
    ..post('/api/login', login)
    ..get('/api/orders/mine', (Request r) => listOrders(r, admin: false))
    ..get('/api/orders', (Request r) => listOrders(r, admin: true))
    ..post('/api/orders', createOrder)
    ..get('/api/orders/<oid>/files/<fid>', download)
    ..post('/api/orders/<oid>/finish', finish);

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(
      Cascade()
          .add(router.call)
          .add(createStaticHandler('web', defaultDocument: 'admin.html'))
          .handler);
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
  await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Gamotin Services server on :$port');
}
