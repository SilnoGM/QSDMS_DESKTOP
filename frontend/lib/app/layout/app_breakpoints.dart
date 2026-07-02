import 'app_layout_mode.dart';

/// QSDMS 桌面端统一断点。
///
/// 断点来自 `docs/响应式设计方案.md`，侧边栏、表格和主框架共享同一套
/// 判断标准，避免不同组件对同一窗口宽度给出不同布局结果。
abstract final class AppBreakpoints {
  static const compactDesktop = 1280.0;
  static const standardDesktop = 1440.0;
  static const wideDesktop = 1920.0;
  static const ultraWideDesktop = 2560.0;

  /// 根据实际可用宽度解析当前布局模式。
  static AppLayoutMode resolve(double width) {
    if (width >= ultraWideDesktop) {
      return AppLayoutMode.ultraWideDesktop;
    }

    if (width >= wideDesktop) {
      return AppLayoutMode.wideDesktop;
    }

    if (width >= standardDesktop) {
      return AppLayoutMode.standardDesktop;
    }

    return AppLayoutMode.compactDesktop;
  }
}
