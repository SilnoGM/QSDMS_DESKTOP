import 'dart:io';

import 'package:flutter/foundation.dart';

/// 桌面端外部链接打开器。
///
/// 当前项目未引入 `url_launcher`，先使用系统命令打开浏览器。后续若公告 API
/// 需要更完整的链接安全策略，可在此处集中加入域名白名单和 URL 规范化。
abstract final class ExternalUrlOpener {
  static Future<void> open(String url) async {
    final launchCommand = _buildLaunchCommand(url);
    if (launchCommand == null) {
      return;
    }

    try {
      await Process.start(
        launchCommand.executable,
        launchCommand.arguments,
        mode: ProcessStartMode.detached,
      );
    } on Object catch (error) {
      debugPrint('ExternalUrlOpener failed: $error');
    }
  }

  static _ExternalUrlLaunchCommand? _buildLaunchCommand(String url) {
    final normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) {
      return null;
    }

    if (Platform.isMacOS) {
      return _ExternalUrlLaunchCommand('open', [normalizedUrl]);
    }

    if (Platform.isWindows) {
      return _ExternalUrlLaunchCommand('rundll32', [
        'url.dll,FileProtocolHandler',
        normalizedUrl,
      ]);
    }

    return _ExternalUrlLaunchCommand('xdg-open', [normalizedUrl]);
  }
}

class _ExternalUrlLaunchCommand {
  const _ExternalUrlLaunchCommand(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}
