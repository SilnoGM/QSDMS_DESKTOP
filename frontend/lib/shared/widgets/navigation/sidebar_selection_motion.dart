/// 侧边栏菜单选中背景的跨路由过渡记忆。
///
/// 当前桌面端每个业务页面都会重新创建一棵 `AppShell`。如果菜单点击后直接
/// 替换路由，新的侧边栏只能知道“当前选中项”，不知道“旧选中项”，选中背景
/// 就会在新页面第一帧直接跳到目标位置。这里用一个很窄的内存态记录本次
/// 默认菜单导航的起点和终点，让新侧边栏可以从旧菜单项位置继续播放动画。
abstract final class SidebarSelectionMotion {
  static SidebarSelectionTransition? _pendingTransition;

  /// 记录一次由侧边栏菜单触发的默认路由切换。
  static void begin({required String fromItemId, required String toItemId}) {
    if (fromItemId == toItemId) {
      _pendingTransition = null;
      return;
    }

    _pendingTransition = SidebarSelectionTransition(
      fromItemId: fromItemId,
      toItemId: toItemId,
    );
  }

  /// 只允许目标菜单项消费对应的过渡，避免陈旧状态影响后续页面构建。
  static SidebarSelectionTransition? consumeFor(String activeItemId) {
    final transition = _pendingTransition;
    if (transition == null || transition.toItemId != activeItemId) {
      return null;
    }

    _pendingTransition = null;
    return transition;
  }
}

/// 一次菜单选中背景的跨路由位移信息。
class SidebarSelectionTransition {
  const SidebarSelectionTransition({
    required this.fromItemId,
    required this.toItemId,
  });

  final String fromItemId;
  final String toItemId;
}
