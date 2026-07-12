import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;

// ---- 数据库连接 ----
final _pool = MySQLConnectionPool(
  host: '127.0.0.1',
  port: 3306,
  userName: 'root',
  password: 'Zhy20060211zhyvanitas@',
  databaseName: 'PuzzleGame',
  maxConnections: 10,
);

// ---- 工具函数 ----
String _hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

Map _ok([String? msg]) => {'success': true, 'message': msg ?? 'ok'};
Map _fail(String msg) => {'success': false, 'message': msg};

// ---- API 路由 ----
final _router = Router()
  // POST /api/register
  ..post('/api/register', (Request req) async {
    try {
      final body = jsonDecode(await req.readAsString());
      final phone = body['phone']?.toString().trim();
      final password = body['password']?.toString();

      if (phone == null || phone.isEmpty) {
        return Response.ok(jsonEncode(_fail('手机号不能为空')),
            headers: {'Content-Type': 'application/json'});
      }
      if (password == null || password.length < 6) {
        return Response.ok(jsonEncode(_fail('密码至少 6 位')),
            headers: {'Content-Type': 'application/json'});
      }

      final check = await _pool.execute(
        'SELECT id FROM users WHERE phone = :phone',
        {'phone': phone},
      );
      if (check.rows.isNotEmpty) {
        return Response.ok(jsonEncode(_fail('该手机号已注册')),
            headers: {'Content-Type': 'application/json'});
      }

      await _pool.execute(
        'INSERT INTO users (phone, password) VALUES (:phone, :password)',
        {'phone': phone, 'password': _hashPassword(password)},
      );

      return Response.ok(jsonEncode(_ok('注册成功')),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.ok(jsonEncode(_fail('服务器错误：$e')),
          headers: {'Content-Type': 'application/json'});
    }
  })

  // POST /api/login
  ..post('/api/login', (Request req) async {
    try {
      final body = jsonDecode(await req.readAsString());
      final phone = body['phone']?.toString().trim();
      final password = body['password']?.toString();

      if (phone == null || phone.isEmpty || password == null || password.isEmpty) {
        return Response.ok(jsonEncode(_fail('请输入手机号和密码')),
            headers: {'Content-Type': 'application/json'});
      }

      final result = await _pool.execute(
        'SELECT id, password FROM users WHERE phone = :phone',
        {'phone': phone},
      );
      if (result.rows.isEmpty) {
        return Response.ok(jsonEncode(_fail('手机号未注册')),
            headers: {'Content-Type': 'application/json'});
      }

      final row = result.rows.first;
      final storedHash = row.colAt(1)!;
      if (storedHash != _hashPassword(password)) {
        return Response.ok(jsonEncode(_fail('密码错误')),
            headers: {'Content-Type': 'application/json'});
      }

      return Response.ok(
          jsonEncode({'success': true, 'message': '登录成功', 'user_id': row.colAt(0)}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.ok(jsonEncode(_fail('服务器错误：$e')),
          headers: {'Content-Type': 'application/json'});
    }
  });

// ---- CORS 中间件 ----
Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request req) async {
      // 预检请求直接返回 200
      if (req.method == 'OPTIONS') {
        return Response(200,
            headers: _corsHeaders);
      }
      final res = await innerHandler(req);
      return res.change(headers: _corsHeaders);
    };
  };
}

final _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

// ---- 启动服务器 ----
void main() async {
  try {
    await _pool.execute('SELECT 1');
    print('MySQL 连接成功');
  } catch (e) {
    print('MySQL 连接失败：$e');
    exit(1);
  }

  final handler = const Pipeline()
      .addMiddleware(corsMiddleware())
      .addHandler(_router);
  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('服务器已启动：http://localhost:${server.port}');
  print('接口列表：');
  print('  POST http://localhost:${server.port}/api/register');
  print('  POST http://localhost:${server.port}/api/login');
}
