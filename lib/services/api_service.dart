import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8080/api';
    }

    try {
      final result = Process.runSync('getprop', ['ro.product.model']);
      if (result.stdout.toString().toLowerCase().contains('sdk') ||
          result.stdout.toString().toLowerCase().contains('generic') ||
          result.stdout.toString().toLowerCase().contains('emulator')) {
        return 'http://10.0.2.2:8080/api';
      }
    } catch (_) {}

    return 'http://localhost:8080/api';
  }

  // ---- 注册 ----
  static Future<Map<String, dynamic>> register({
    required String username,
    required String phone,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'phone': phone, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ---- 登录 ----
  static Future<Map<String, dynamic>> login({
    required String account,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'account': account, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ---- 修改用户名 ----
  static Future<Map<String, dynamic>> updateUsername({
    required String username,
    required String newUsername,
    required String password,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/update-username'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'newUsername': newUsername, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ---- 修改密码 ----
  static Future<Map<String, dynamic>> updatePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/update-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'oldPassword': oldPassword, 'newPassword': newPassword}),
    );
    return jsonDecode(res.body);
  }

  // ---- 修改手机号 ----
  static Future<Map<String, dynamic>> updatePhone({
    required String username,
    required String newPhone,
    required String password,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/update-phone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'newPhone': newPhone, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ---- 注销账号 ----
  static Future<Map<String, dynamic>> deleteAccount({
    required String username,
    required String phone,
    required String password,
  }) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/user/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'phone': phone, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ---- 保存游戏进度 ----
  static Future<Map<String, dynamic>> saveGame({
    required String username,
    required int boardSize,
    required List<List<int>> cells,
    required List<List<Set<int>>> notes,
    required List<List<int>> solution,
    required List<List<bool>> given,
    required int seconds,
    required int errors,
    required bool isKiller,
    required String killerDifficulty,
    required List<dynamic>? cages,
  }) async {
    // notes 序列化：Set<int> → List<int>
    final notesJson = notes.map((row) =>
      row.map((s) => s.toList()).toList()
    ).toList();
    final cagesJson = cages ?? [];

    final res = await http.post(
      Uri.parse('$baseUrl/save'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'boardSize': boardSize,
        'cells': cells,
        'notes': notesJson,
        'solution': solution,
        'given': given.map((row) => row.map((b) => b ? 1 : 0).toList()).toList(),
        'seconds': seconds,
        'errors': errors,
        'isKiller': isKiller,
        'killerDifficulty': killerDifficulty,
        'cages': cagesJson,
      }),
    );
    return jsonDecode(res.body);
  }

  // ---- 加载最近存档 ----
  static Future<Map<String, dynamic>> loadGame({
    required String username,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/load?username=${Uri.encodeComponent(username)}'),
    );
    return jsonDecode(res.body);
  }

  // ---- 提交游戏结果（更新胜率+积分） ----
  static Future<Map<String, dynamic>> submitScore({
    required String username,
    required bool won,
    String gameMode = '',
    int boardSize = 3,
    int score = 0,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/rank/submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'won': won,
        'gameMode': gameMode,
        'boardSize': boardSize,
        'score': score,
      }),
    );
    return jsonDecode(res.body);
  }

  // ---- 获取排行榜（完成数 + 胜率） ----
  static Future<Map<String, dynamic>> getRankList() async {
    final res = await http.get(Uri.parse('$baseUrl/rank/list'));
    return jsonDecode(res.body);
  }

  // ---- 获取个人统计 ----
  static Future<Map<String, dynamic>> getUserStats({
    required String username,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/rank/user?username=${Uri.encodeComponent(username)}'),
    );
    return jsonDecode(res.body);
  }
}
