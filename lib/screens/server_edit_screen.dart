import 'package:flutter/material.dart';

import '../models/server_entry.dart';
import '../services/server_store.dart';

class ServerEditScreen extends StatefulWidget {
  final ServerEntry? existing;
  const ServerEditScreen({super.key, this.existing});

  @override
  State<ServerEditScreen> createState() => _ServerEditScreenState();
}

class _ServerEditScreenState extends State<ServerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _urlCtrl = TextEditingController(text: widget.existing?.url ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final url = normalizePanelUrl(_urlCtrl.text)!;
    var name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      name = Uri.parse(url).host;
    }
    final entry = widget.existing?.copyWith(name: name, url: url) ??
        ServerEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          url: url,
        );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? '编辑面板' : '添加面板')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: '名称（可选）',
                hintText: '例如：我的服务器',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'KPanel 访问地址',
                hintText: 'https://panel.example.com 或 http://1.2.3.4:8080',
                border: OutlineInputBorder(),
                helperText: '不写协议时默认按 https:// 处理。自签名证书也能打开。',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请填写面板地址';
                if (normalizePanelUrl(v) == null) return '地址格式不对，请检查';
                return null;
              },
            ),
            SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(Icons.save_outlined),
              label: Text(editing ? '保存修改' : '添加'),
            ),
          ],
        ),
      ),
    );
  }
}
