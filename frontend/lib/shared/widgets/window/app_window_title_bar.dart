import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 应用窗口栏平台布局模式。
///
/// macOS 和 Windows 的窗口控制按钮位置不同，这里只抽象按钮区域位置，
/// 避免业务布局直接判断 `TargetPlatform`。
enum AppWindowTitleBarPlatform { macos, windows, other }

/// QSDMS 桌面端自定义窗口栏。
///
/// 原生标题栏隐藏后，窗口拖拽、标题展示和 Windows 窗口按钮由这个组件承接。
/// macOS 仍保留系统红黄绿按钮，所以只在左侧预留不可点击布局空间。
class AppWindowTitleBar extends StatelessWidget {
  const AppWindowTitleBar({
    this.platform,
    this.title = 'QSDMS-千树数据管理系统',
    super.key,
  });

  static const height = 40.0;
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
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5EAF0))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentPlatform == AppWindowTitleBarPlatform.macos)
              const _MacosWindowControls(),
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

/// macOS 左侧窗口控制按钮。
///
/// 原生红黄绿按钮在隐藏标题栏后无法通过 Flutter 调整垂直位置，因此这里使用
/// Flutter 自绘按钮，保证它们稳定居中在自定义窗口栏里。
class _MacosWindowControls extends StatelessWidget {
  const _MacosWindowControls();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('macos-window-controls'),
      height: AppWindowTitleBar.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 14),
          _MacosWindowControlButton(
            tooltip: '关闭',
            color: const Color(0xFFFF5F57),
            borderColor: const Color(0xFFE0443E),
            onPressed: windowManager.close,
          ),
          _MacosWindowControlButton(
            tooltip: '最小化',
            color: const Color(0xFFFEBC2E),
            borderColor: const Color(0xFFD89A1A),
            onPressed: windowManager.minimize,
          ),
          const _MacosWindowControlButton(
            tooltip: '缩放',
            color: Color(0xFF28C840),
            borderColor: Color(0xFF1E9B31),
            onPressed: _WindowsWindowControls._toggleMaximize,
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

/// macOS 自绘交通灯按钮。
///
/// 可点击区域使用完整窗口栏高度，视觉圆点放在 `Center` 中，避免不同平台字体、
/// 设备像素比或 hover 区域影响垂直对齐。
class _MacosWindowControlButton extends StatelessWidget {
  const _MacosWindowControlButton({
    required this.tooltip,
    required this.color,
    required this.borderColor,
    required this.onPressed,
  });

  final String tooltip;
  final Color color;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: SizedBox(
            width: 20,
            height: AppWindowTitleBar.height,
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 窗口栏标题展示区。
///
/// 该区域同时作为拖拽区域，内部不放按钮或输入控件，避免和窗口拖拽手势冲突。
class _WindowTitleArea extends StatelessWidget {
  const _WindowTitleArea({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
