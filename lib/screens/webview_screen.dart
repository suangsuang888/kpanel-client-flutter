import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/server_entry.dart';

/// 打开某个 KPanel 面板的 WebView 页面。
///
/// KPanel 常用自签名 HTTPS，这里在 onReceivedServerTrustAuthRequest 里直接放行，
/// 否则自签名证书的面板会打不开。登录 Cookie 由 WebView 自带存储持久化，
/// 下次打开不用重复登录（直到面板 Session 过期）。
class WebViewScreen extends StatefulWidget {
  final ServerEntry server;
  const WebViewScreen({super.key, required this.server});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefresh;
  double _progress = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _pullToRefresh = PullToRefreshController(
      onRefresh: () async {
        await _controller?.reload();
      },
    );
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.server.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _clearLoginState() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('清除登录状态？'),
        content: Text('会清掉这个面板在本地保存的 Cookie 和缓存，下次打开需要重新登录。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('清除')),
        ],
      ),
    );
    if (ok != true) return;
    await CookieManager.instance().deleteAllCookies();
    await _controller?.clearCache();
    await _controller?.reload();
  }

  Future<bool> _handleBack() async {
    final c = _controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
      return false; // 已在网页内后退，不退出页面
    }
    return true; // 允许退出
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.server.name.isEmpty ? widget.server.url : widget.server.name;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              tooltip: '刷新',
              onPressed: () => _controller?.reload(),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'browser') await _openExternally();
                if (v == 'clear') await _clearLoginState();
                if (v == 'home') {
                  await _controller?.loadUrl(
                    urlRequest:
                        URLRequest(url: WebUri(widget.server.url)),
                  );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'home', child: Text('回到面板首页')),
                PopupMenuItem(
                    value: 'browser', child: Text('用系统浏览器打开')),
                PopupMenuItem(
                    value: 'clear', child: Text('清除登录状态')),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest:
                  URLRequest(url: WebUri(widget.server.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                cacheEnabled: true,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                supportZoom: true,
                builtInZoomControls: false,
                displayZoomControls: false,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                allowFileAccess: true,
                allowContentAccess: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                javaScriptCanOpenWindowsAutomatically: true,
                supportMultipleWindows: false,
                transparentBackground: false,
              ),
              pullToRefreshController: _pullToRefresh,
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onProgressChanged: (controller, progress) {
                if (!mounted) return;
                setState(() => _progress = progress / 100);
              },
              onLoadStart: (controller, url) {
                if (!mounted) return;
                setState(() => _loadError = null);
              },
              onLoadStop: (controller, url) async {
                await _pullToRefresh?.endRefreshing();
              },
              onReceivedServerTrustAuthRequest:
                  (controller, challenge) async {
                // KPanel 常见自签名证书，直接放行，否则面板打不开。
                return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.PROCEED,
                );
              },
              onReceivedError: (controller, request, error) async {
                await _pullToRefresh?.endRefreshing();
                if (request.isForMainFrame != true) return;
                if (!mounted) return;
                setState(() {
                  _loadError = error.description;
                });
              },
              onDownloadStartRequest: (controller, request) async {
                // 下载交给系统浏览器/下载器处理（需登录态的文件可能下不了，
                // 那种请在面板里用它自带的下载方式）。
                final uri = Uri.tryParse(request.url.toString());
                if (uri != null) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
              onCreateWindow: (controller, createWindowAction) async {
                // 面板里 target=_blank 的链接：在当前 WebView 打开，避免丢窗口。
                final url = createWindowAction.request.url;
                if (url != null) {
                  await controller.loadUrl(
                      urlRequest: URLRequest(url: url));
                }
                return true;
              },
            ),
            if (_progress < 1)
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            if (_loadError != null)
              _errorOverlay(_loadError!),
          ],
        ),
      ),
    );
  }

  Widget _errorOverlay(String message) {
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 52, color: Colors.grey),
            SizedBox(height: 16),
            Text('面板加载失败',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(
              '${widget.server.url}\n$message\n\n请检查：面板是否在运行、地址和端口对不对、手机/电脑能否连上那台服务器。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                setState(() => _loadError = null);
                _controller?.reload();
              },
              icon: Icon(Icons.refresh),
              label: Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
