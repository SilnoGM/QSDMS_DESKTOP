import 'package:flutter/material.dart';

/// QSDMS 产品级全局色彩变量。
///
/// 业务指定的品牌色和功能色只在此文件维护，业务组件禁止再次硬编码这些
/// Hex 值。组件如果需要更浅的背景、边框或文本色，也从这里读取语义化
/// 变量，避免后续换肤时逐文件追颜色。
abstract final class AppColors {
  /// 品牌色：关键行动点、操作状态、重要信息高亮、图形化主色。
  static const Color brand = Color(0xFF1677FF);

  /// 成功色：正向状态、完成状态、通过状态。
  static const Color success = Color(0xFF73BD3A);

  /// 出错失败色：删除、退出、失败、危险操作提示。
  static const Color error = Color(0xFFEB5F55);

  /// 提醒色：待处理、警告、需要关注但不阻断的状态。
  static const Color warning = Color(0xFFEFAE3B);

  /// 链接色：文本链接、可跳转信息和弱化行动入口。
  static const Color link = Color(0xFF4290F9);

  /// 纯白色：卡片、侧边栏、窗口栏等主要承载面。
  static const Color white = Color(0xFFFFFFFF);

  /// 透明色：未选中菜单背景等需要保留布局但不显示底色的场景。
  static const Color transparent = Color(0x00000000);

  /// 窗口启动背景色：传给原生窗口，避免 Flutter 首帧前出现色差。
  static const Color windowBackground = Color(0xFFFAFBFC);

  /// 页面背景色：内容区和 Scaffold 的统一浅灰底。
  static const Color pageBackground = Color(0xFFF6F8FA);

  /// 默认承载面颜色：侧边栏、标题栏、弹窗内部等。
  static const Color surface = white;

  /// 默认边框色：窗口栏底线、侧边栏右边线等低强调分割线。
  static const Color border = Color(0xFFE5EAF0);

  /// 品牌浅背景：菜单激活态、公告卡片等低强调品牌提示区域。
  static const Color brandSubtle = Color(0xFFE6F4FF);

  /// 菜单选中态背景：品牌蓝 `#1677FF` 的 8% 透明度。
  ///
  /// 相比固定浅蓝底，这个颜色更轻、更通透，同时仍然跟随品牌主色。
  static const Color brandSelectedBackground = Color(0x141677FF);

  /// 品牌浅边框：品牌浅背景上的边界线。
  static const Color brandSubtleBorder = Color(0xFFBAE0FF);

  /// 品牌深文本：品牌浅背景上的标题或重点文本。
  static const Color brandText = Color(0xFF0958D9);

  /// 一级文本：品牌、用户姓名等最高优先级文本。
  static const Color textPrimary = Color(0xFF101828);

  /// 页面标题文本：页面占位标题等大字号文本。
  static const Color textHeading = Color(0xFF1F2937);

  /// 正文文本：菜单、普通标签等常规阅读文本。
  static const Color textBody = Color(0xFF344054);

  /// 二级文本：说明、角色、辅助信息。
  static const Color textSecondary = Color(0xFF667085);

  /// 三级文本：箭头、禁用图标、弱化辅助信息。
  static const Color textTertiary = Color(0xFF98A2B3);

  /// 弱化正文：公告说明等面积较小但需要可读的文本。
  static const Color textMuted = Color(0xFF475467);
}
