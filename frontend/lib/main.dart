import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app/qsdms_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureDesktopWindow();

  runApp(const QsdmsApp());
}

/// 配置桌面端原生窗口的启动状态。
///
/// 默认尺寸和最小尺寸保持一致，避免内部管理系统在启动或缩放时出现不可用
/// 的窄窗口；标题和背景色也统一放在这里，后续窗口策略集中维护。
Future<void> _configureDesktopWindow() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(1280, 720),
    center: true,
    backgroundColor: Color(0xFFFAFBFC),
    title: 'QSDMS-千树数据管理系统',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
