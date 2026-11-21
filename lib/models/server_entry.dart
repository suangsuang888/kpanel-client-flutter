import 'dart:convert';

/// 一个 KPanel 服务器条目：显示名 + 面板访问地址。
class ServerEntry {
  final String id;
  final String name;
  final String url;

  const ServerEntry({required this.id, required this.name, required this.url});

  ServerEntry copyWith({String? name, String? url}) => ServerEntry(
        id: id,
        name: name ?? this.name,
        url: url ?? this.url,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'url': url};

  factory ServerEntry.fromJson(Map<String, dynamic> json) => ServerEntry(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        url: (json['url'] as String?) ?? '',
      );

  String encode() => jsonEncode(toJson());
}
