import 'package:flutter/material.dart';

import 'app_colors.dart';

/// QSDMS 桌面端基础主题。
///
/// 当前阶段只定义稳定的浅色主题基线，后续再在这个入口扩展表格、表单、
/// 弹窗等组件的统一样式。
abstract final class AppTheme {
  static ThemeData get light {
    // 用品牌色生成 Material 3 色阶，再显式覆盖业务指定的核心色。
    // 这样既保留 Flutter 组件需要的完整色阶，又确保关键行动点不会漂移。
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          error: AppColors.error,
        ).copyWith(
          primary: AppColors.brand,
          error: AppColors.error,
          surface: AppColors.surface,
        );

    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.brand,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.pageBackground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.link),
      ),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    );
  }
}
