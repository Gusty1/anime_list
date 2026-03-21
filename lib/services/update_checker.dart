import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anime_list/utils/logger.dart';

/// GitHub Release 資訊
class UpdateInfo {
  final String latestVersion;
  final String releaseUrl;
  final bool hasUpdate;

  const UpdateInfo({
    required this.latestVersion,
    required this.releaseUrl,
    required this.hasUpdate,
  });
}

/// 版本更新檢查服務
///
/// 透過 GitHub Releases API 取得最新版本，
/// 與本機版本比對後決定是否需要更新。
class UpdateChecker {
  static const String _repoOwner = 'Gusty1';
  static const String _repoName = 'anime_list';
  static const String _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  // TODO: Google Play 正式上架後，將 showUpdateDialog 的連結改為下方 Play Store 連結
  // static const String _playStoreUrl =
  //     'https://play.google.com/store/apps/details?id=你的.package.id';

  /// 檢查是否有新版本
  ///
  /// [dio] 由呼叫端注入（通常傳入 `dioClientProvider` 的實例），
  /// 避免每次呼叫都建立新的 Dio 物件並繞過統一的 interceptor 設定。
  /// 回傳 [UpdateInfo]，若檢查失敗則回傳 null。
  static Future<UpdateInfo?> checkForUpdate({Dio? dio}) async {
    final client = dio ?? Dio();
    final shouldClose = dio == null; // 只有自建的才需要自己關閉
    try {
      final response = await client.get<Map<String, dynamic>>(
        _apiUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;

        // tag_name 可能帶有 'v' 前綴，統一移除
        final String tagName = (data['tag_name'] as String? ?? '').replaceFirst(
          RegExp(r'^v'),
          '',
        );
        final String htmlUrl = data['html_url'] as String? ?? '';

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        final hasUpdate = _isNewerVersion(tagName, currentVersion);

        appLogger.d(
          '版本檢查: 本機=$currentVersion, 最新=$tagName, '
          '需要更新=$hasUpdate',
        );

        return UpdateInfo(
          latestVersion: tagName,
          releaseUrl: htmlUrl,
          hasUpdate: hasUpdate,
        );
      }
    } catch (e) {
      appLogger.e('檢查更新失敗: $e');
    } finally {
      if (shouldClose) client.close();
    }
    return null;
  }

  /// 比較版本號（語意化版本），判斷 [latest] 是否比 [current] 新
  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      // 補齊長度至 3 段
      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false; // 版本相同
    } catch (e) {
      appLogger.e('版本號解析失敗: latest=$latest, current=$current');
      return false;
    }
  }

  /// 顯示更新提示 Dialog
  static Future<void> showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.system_update, size: 48),
          title: const Text('發現新版本'),
          content: Text('目前版本與最新版本 ${updateInfo.latestVersion} 不同，\n是否前往下載更新？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('稍後再說'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                launchUrl(
                  Uri.parse(updateInfo.releaseUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('前往更新'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        );
      },
    );
  }
}
