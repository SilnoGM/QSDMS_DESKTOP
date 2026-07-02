import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app/theme/app_colors.dart';

/// 应用窗口栏平台布局模式。
///
/// macOS 和 Windows 的窗口控制按钮位置不同，这里只抽象按钮区域位置，
/// 避免业务布局直接判断 `TargetPlatform`。
enum AppWindowTitleBarPlatform { macos, windows, other }

/// QSDMS 桌面端自定义窗口栏。
///
/// 原生标题栏隐藏后，窗口拖拽和 Windows 窗口按钮由这个组件承接。
/// macOS 仍保留系统红黄绿按钮，所以只在左侧预留不可点击布局空间。
class AppWindowTitleBar extends StatelessWidget {
  const AppWindowTitleBar({
    this.platform,
    this.title = 'QSDMS-千树数据管理系统',
    super.key,
  });

  static const height = 40.0;
  static const _macosNativeControlsWidth = 78.0;

  final AppWindowTitleBarPlatform? platform;
  final String title;

  AppWindowTitleBarPlatform get _resolvedPlatform {
    if (platform != null) {
      return platform!;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS => AppWindowTitleBarPlatform.macos,
      TargetPlatform.windows => AppWindowTitleBarPlatform.windows,
      _ => AppWindowTitleBarPlatform.other,
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentPlatform = _resolvedPlatform;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentPlatform == AppWindowTitleBarPlatform.macos)
              const SizedBox(
                key: ValueKey('macos-native-window-controls-space'),
                width: _macosNativeControlsWidth,
              ),
            Expanded(
              child: DragToMoveArea(child: _WindowTitleArea(title: title)),
            ),
            if (currentPlatform == AppWindowTitleBarPlatform.windows)
              const _WindowsWindowControls(),
          ],
        ),
      ),
    );
  }
}

/// 窗口栏空白拖拽区。
///
/// 标题不再可见展示，但保留语义标签，方便后续需要辅助功能或恢复显示时
/// 继续复用 `title` 配置。
class _WindowTitleArea extends StatelessWidget {
  const _WindowTitleArea({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(label: title, child: const SizedBox.expand());
  }
}

/// Windows 右侧窗口控制按钮。
///
/// 仅在 Windows 布局中渲染。macOS 继续使用系统原生红黄绿按钮，避免破坏平台
/// 操作习惯和辅助功能行为。
class _WindowsWindowControls extends StatelessWidget {
  const _WindowsWindowControls();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('windows-window-controls'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: '最小化',
          child: WindowCaptionButton.minimize(
            brightness: Brightness.light,
            onPressed: windowManager.minimize,
          ),
        ),
        Tooltip(
          message: '最大化',
          child: WindowCaptionButton.maximize(
            brightness: Brightness.light,
            onPressed: _toggleMaximize,
          ),
        ),
        Tooltip(
          message: '关闭',
          child: WindowCaptionButton.close(
            brightness: Brightness.light,
            onPressed: windowManager.close,
          ),
        ),
      ],
    );
  }

  static Future<void> _toggleMaximize() async {
    final isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
      return;
    }

    await windowManager.maximize();
  }
}
