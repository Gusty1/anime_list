import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:anime_list/constants.dart';
import 'package:anime_list/providers/anime_database_provider.dart';
import 'package:anime_list/providers/api_provider.dart';
import 'package:anime_list/providers/favorite_provider.dart';
import 'package:anime_list/services/update_checker.dart';
import 'package:anime_list/widgets/toast_utils.dart';
import 'package:anime_list/widgets/setting/theme_switch.dart';

/// 設定頁面
///
/// 包含主題切換、清除收藏資料、版本資訊、檢查更新和致謝連結。
class SettingMainScreen extends ConsumerStatefulWidget {
  const SettingMainScreen({super.key});

  @override
  ConsumerState<SettingMainScreen> createState() => _SettingMainScreenState();
}

class _SettingMainScreenState extends ConsumerState<SettingMainScreen> {
  PackageInfo? _packageInfo;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  /// 異步載入 App 版本資訊
  Future<void> _loadPackageInfo() async {
    if (!mounted) return;
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = packageInfo;
      });
    }
  }

  /// 開啟 ACG Taiwan Anime List 網站
  Future<void> _launchUrl(BuildContext context) async {
    if (!mounted) return;
    final url = Uri.parse(originUrl);
    if (!await launchUrl(url)) {
      if (context.mounted) {
        ToastUtils.showShortToast(context, '無法開啟連結');
      }
    }
  }

  /// 手動檢查更新
  Future<void> _checkUpdate() async {
    if (_isCheckingUpdate || !mounted) return;

    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final dio = ref.read(dioClientProvider).dio;
      final updateInfo = await UpdateChecker.checkForUpdate(dio: dio);

      if (!mounted) return;

      if (updateInfo == null) {
        ToastUtils.showShortToast(context, '檢查更新失敗，請稍後再試');
      } else if (updateInfo.hasUpdate) {
        UpdateChecker.showUpdateDialog(context, updateInfo);
      } else {
        ToastUtils.showShortToast(context, '已是最新版本 ✓');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  /// 顯示清除資料確認對話框
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('確定清除'),
          content: const Text('所有收藏的動漫都會被清除，確定繼續?'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                final dbService = ref.read(animeDatabaseServiceProvider);
                await dbService.clearAllAnimeItems();
                ref.invalidate(favoriteProvider);
                if (dialogContext.mounted) {
                  ToastUtils.showShortToast(dialogContext, '清除成功');
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('確定'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const ThemeSwitch(),
        const Divider(indent: 16, endIndent: 16),
        _buildDataSection(context),
        const Divider(indent: 16, endIndent: 16),
        _buildAboutSection(context),
        const Divider(indent: 16, endIndent: 16),
        _buildUpdateSection(context),
      ],
    );
  }

  /// 清除資料區塊
  Widget _buildDataSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.delete_outline, color: colorScheme.error),
      title: const Text('清除收藏資料'),
      subtitle: const Text('刪除所有已收藏的動漫'),
      onTap: () => _showClearDataDialog(context),
    );
  }

  /// 關於區塊（致謝與網站連結）
  Widget _buildAboutSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.info_outline, color: colorScheme.primary),
      title: const Text('關於'),
      subtitle: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          children: <TextSpan>[
            const TextSpan(text: '本 APP 是模仿'),
            TextSpan(
              text: '這個網站',
              style: TextStyle(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer:
                  TapGestureRecognizer()..onTap = () => _launchUrl(context),
            ),
            const TextSpan(text: '製作的\n感謝該網站提供的資料 (･ω´･ )'),
          ],
        ),
      ),
      isThreeLine: true,
    );
  }

  /// 版本資訊與更新區塊
  Widget _buildUpdateSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.info_outline, color: colorScheme.primary),
      title: Text(
        'v${_packageInfo?.version ?? loadingMessage}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: const Text('點擊檢查更新'),
      trailing:
          _isCheckingUpdate
              ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
              : Icon(Icons.system_update_outlined, color: colorScheme.primary),
      onTap: _isCheckingUpdate ? null : _checkUpdate,
    );
  }
}
