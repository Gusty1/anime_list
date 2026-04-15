import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:anime_list/constants.dart';
import 'package:anime_list/providers/anime_database_provider.dart';
import 'package:anime_list/providers/api_provider.dart';
import 'package:anime_list/providers/favorite_provider.dart';
import 'package:anime_list/providers/theme_provider.dart';
import 'package:anime_list/services/update_checker.dart';
import 'package:anime_list/widgets/toast_utils.dart';

/// 設定頁面
///
/// 簡約 Material 3 風格，以 Card 分區塊呈現：外觀、資料、關於。
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

  /// 開啟指定網址
  Future<void> _launchUrl(BuildContext context, String url) async {
    if (!mounted) return;
    if (!await launchUrl(Uri.parse(url))) {
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = ref.watch(themeNotifierProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // ── 外觀 ──
        _SectionLabel(label: '外觀', textTheme: textTheme, colorScheme: colorScheme),
        const SizedBox(height: 6),
        Card(
          margin: EdgeInsets.zero,
          child: SwitchListTile(
            secondary: Icon(
              isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
              color: colorScheme.primary,
            ),
            title: const Text('深色模式'),
            subtitle: Text(isDark ? '已開啟' : '已關閉'),
            value: isDark,
            onChanged: (value) {
              ref.read(themeNotifierProvider.notifier).setDarkMode(value);
            },
          ),
        ),

        const SizedBox(height: 20),

        // ── 資料 ──
        _SectionLabel(label: '資料', textTheme: textTheme, colorScheme: colorScheme),
        const SizedBox(height: 6),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: colorScheme.error),
            title: const Text('清除收藏資料'),
            subtitle: const Text('刪除所有已收藏的動漫'),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => _showClearDataDialog(context),
          ),
        ),

        const SizedBox(height: 20),

        // ── 關於 ──
        _SectionLabel(label: '關於', textTheme: textTheme, colorScheme: colorScheme),
        const SizedBox(height: 6),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              // 版本與更新
              ListTile(
                leading: Icon(Icons.info_outline, color: colorScheme.primary),
                title: Text('版本 ${_packageInfo?.version ?? loadingMessage}'),
                subtitle: const Text('點擊檢查更新'),
                trailing: _isCheckingUpdate
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.system_update_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                onTap: _isCheckingUpdate ? null : _checkUpdate,
              ),

              Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant),

              // 致謝
              ListTile(
                leading: Icon(Icons.favorite_outline, color: colorScheme.primary),
                title: const Text('致謝'),
                subtitle: RichText(
                  text: TextSpan(
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    children: <TextSpan>[
                      const TextSpan(text: '動漫資料來源：'),
                      TextSpan(
                        text: 'ACG Taiwan Anime List',
                        style: TextStyle(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchUrl(context, originUrl),
                      ),
                      const TextSpan(text: '\nPV 來源：'),
                      TextSpan(
                        text: 'MyAnimeList',
                        style: TextStyle(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchUrl(context, malUrl),
                      ),
                    ],
                  ),
                ),
                isThreeLine: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

/// 區塊標題 Label
class _SectionLabel extends StatelessWidget {
  final String label;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _SectionLabel({
    required this.label,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
