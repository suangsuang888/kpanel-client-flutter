# KPanel 客户端（WebView 套壳）

把服务器上的 [KPanel](https://github.com/kejilion/KPanel) 面板装进一个安卓 / Windows 程序里，方便远程管理。

这不是把 KPanel 本体搬到手机/电脑上运行（KPanel 管的是 Linux 主机，依赖 Docker/systemd，只能跑在服务器上），而是一个**客户端壳**：保存你的面板地址，点开就在内置浏览器里打开面板网页，登录状态会保留。

## 功能

- 服务器列表：添加 / 编辑 / 删除多个 KPanel 面板地址
- 内置 WebView 打开面板，自签名 HTTPS 证书可直接打开
- 登录 Cookie 持久化，下次打开不用重复登录
- 下拉刷新、网页内后退、加载失败重试
- 菜单：回到面板首页、用系统浏览器打开、清除登录状态

## 使用

1. 先在你的 Linux 服务器上部署好 KPanel（见官方教程）。
2. 打开本 App，点「添加面板」，填面板访问地址，例如 `https://panel.example.com` 或 `http://1.2.3.4:8080`（不写协议默认 https）。
3. 点条目进入面板，用面板自己的账号登录即可。

> 面板地址要能从你的手机/电脑连通（公网域名、端口映射或内网/Tailscale 等）。如果面板只监听内网，先确保设备在同一网络。

## 构建

本仓库只放 Dart 源码（`lib/`）和 CI 配置，平台工程由 CI 用 `flutter create` 现场生成：

- 安卓：`flutter build apk --release`（GitHub Actions 产出 APK）
- Windows：`flutter build windows --release`（GitHub Actions 产出 zip，解压后运行 `kpanel_client.exe`；需要系统装有 WebView2 运行时，Win10/11 一般自带）

本地构建：

```bash
flutter create --platforms=android,windows --project-name kpanel_client --org com.suangsuang .
# 恢复本仓库的 lib/、pubspec.yaml、analysis_options.yaml 后：
flutter pub get
flutter build apk --release        # 安卓
flutter build windows --release    # Windows
```

安卓 release 包记得在 `AndroidManifest.xml` 加 INTERNET 权限（CI 里已自动处理）。

## 说明

- KPanel 本体为 AGPL-3.0；本客户端只是套壳访问你自己的面板，不包含 KPanel 代码。
