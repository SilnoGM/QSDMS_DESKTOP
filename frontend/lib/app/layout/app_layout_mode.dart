/// 桌面端主框架的布局模式。
///
/// 业务页面不直接读取窗口宽度，而是使用这个枚举判断当前应采用哪种
/// 布局密度和信息展示策略，避免断点逻辑散落在各个页面里。
enum AppLayoutMode {
  compactDesktop,
  standardDesktop,
  wideDesktop,
  ultraWideDesktop,
}
