import 'package:flutter/material.dart';

/// QSDMS 桌面端首页。
///
/// 当前按需求清空首页所有可见内容，只保留空白页面骨架，确保路由仍可正常
/// 挂载，后续需要恢复工作台时再重新放入具体组件。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand());
  }
}
