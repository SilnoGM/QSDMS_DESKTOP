import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsdms_desktop_frontend/app/theme/app_colors.dart';
import 'package:qsdms_desktop_frontend/app/theme/app_theme.dart';

void main() {
  test('产品级色彩体系定义为全局变量', () {
    expect(AppColors.brand, const Color(0xFF1677FF));
    expect(AppColors.success, const Color(0xFF73BD3A));
    expect(AppColors.error, const Color(0xFFEB5F55));
    expect(AppColors.warning, const Color(0xFFEFAE3B));
    expect(AppColors.link, const Color(0xFF4290F9));
    expect(AppColors.brandSelectedGradientStart, const Color(0xFF1677FF));
    expect(AppColors.brandSelectedGradientEnd, const Color(0xFF4290F9));
    expect(AppColors.brandSelectedShadow, const Color(0x591677FF));
    expect(AppColors.menuHoverBackground, const Color(0x181677FF));
  });

  test('浅色主题使用品牌色作为主色来源', () {
    final theme = AppTheme.light;

    expect(theme.colorScheme.primary, AppColors.brand);
    expect(theme.primaryColor, AppColors.brand);
    expect(
      theme.textButtonTheme.style?.foregroundColor?.resolve({}),
      AppColors.link,
    );
  });
}
