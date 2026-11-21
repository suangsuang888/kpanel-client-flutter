import 'package:flutter/material.dart';

import '../models/server_entry.dart';
import '../services/server_store.dart';
import 'server_edit_screen.dart';
import 'webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = ServerStore();
  List<ServerEntry> _servers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await _store.load();
    if (!mounted) return;
    setState(() {
      _servers = list;
      _loading = false;
    });
  }

  Future<void> _addOrEdit([ServerEntry? existing]) async {
    final result = await Navigator.of(context).push<ServerEntry>(
      MaterialPageRoute(
        builder: (_) => ServerEditScreen(existing: existing),
      ),
    );
    if (result == null) return;
    setState(() {
      if (existing == null) {
        _servers = [..._servers, result];
      } else {
        _servers = _servers
            .map((e) => e.id == result.id ? result : e)
            .toList();
      }
    });
    await _store.save(_servers);
  }

  Future<void> _delete(ServerEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除「${entry.name}」？'),
        content: Text('只删本地这条记录，不影响服务器上的面板。\n${entry.url}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _servers = _servers.where((e) => e.id != entry.id).toList();
    });
    await _store.save(_servers);
  }

  void _open(ServerEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WebViewScreen(server: entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KPanel 客户端')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _servers.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding: EdgeInsets.all(12),
                  itemCount: _servers.length,
                  separatorBuilder: (_, _) => SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = _servers[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.dns_outlined),
                        ),
                        title: Text(s.name.isEmpty ? s.url : s.name),
                        subtitle: Text(s.url,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _addOrEdit(s);
                            if (v == 'delete') _delete(s);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'edit', child: Text('编辑')),
                            PopupMenuItem(
                                value: 'delete', child: Text('删除')),
                          ],
                        ),
                        onTap: () => _open(s),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: Icon(Icons.add),
        label: Text('添加面板'),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text('还没有添加 KPanel 面板',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(
              '点右下角「添加面板」，填上你服务器上 KPanel 的访问地址\n（例如 https://你的域名:端口 或 http://IP:端口），就能在手机/电脑上远程管理。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
