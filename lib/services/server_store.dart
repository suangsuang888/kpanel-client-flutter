import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_entry.dart';

/// 服务器列表的本地存储（shared_preferences）。
class ServerStore {
  static const _key = 'kpanel_servers_v1';

  Future<List<ServerEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ServerEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<ServerEntry> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(servers.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}

/// 把用户输入的地址规范化：缺协议时补 https://，去掉尾部多余空格。
/// 返回 null 表示地址无效。
String? normalizePanelUrl(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  if (!s.contains('://')) {
    s = 'https://$s';
  }
  final uri = Uri.tryParse(s);
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri.toString();
}
