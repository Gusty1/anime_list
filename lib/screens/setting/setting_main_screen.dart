import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart'; // 引入手勢識別器，用於 TextSpan 的點擊
import '../../constants.dart';
import '../../widgets/toast_utils.dart';
import '../../widgets/setting/theme_switch_row.dart';

// 設定主螢幕
class SettingMainScreen extends ConsumerStatefulWidget {
  const SettingMainScreen({super.key});

  @override
  ConsumerState<SettingMainScreen> createState() => _SettingMainScreenState();
}

class _SettingMainScreenState extends ConsumerState<SettingMainScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    // 在 Widget 初始化時異步載入套件資訊
    _loadPackageInfo();
  }

  // 異步方法用於獲取套件資訊並更新 local state
  Future<void> _loadPackageInfo() async {
    if (!mounted) return;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // 使用 setState 更新 _packageInfo，這會觸發這個 StatefulWidget 重建
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  // 異步函數，開啟爸爸
  Future<void> _launchUrl(BuildContext context) async {
    final Uri url = Uri.parse(originUrl);
    if (!await launchUrl(url)) {
      if (!mounted) return;
      ToastUtils.showShortToast(context, '無法開啟連結');
    }
  }

  // 異步函數，用於開啟郵件客戶端
  Future<void> _launchEmail(BuildContext context) async {
    // 假設 emailAddress, emailSubject 定義在 constants.dart
    final Uri emailLaunchUri = Uri.parse(
      'mailto:$emailAddress?subject=${Uri.encodeComponent(emailSubject)}',
    );
    // 對於非 http/https 的 URI，明確指定 mode: LaunchMode.externalApplication 才有作用
    if (!await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ToastUtils.showShortToast(context, '無法開啟郵件客戶端'); // 呼叫 ToastUtils，需要 context
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      // 使用 ListView 可以避免內容溢出
      children: [
        // 主題開關
        const ThemeSwitchRow(),
        const Divider(),
        // --- 意見回饋和清除資料按鈕 ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          margin: const EdgeInsets.all(10),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              // 意見回饋按鈕
              FilledButton.icon(
                onPressed: () => _launchEmail(context), // 呼叫 state 方法
                icon: const Icon(Icons.email),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  '意見回饋',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // 清除資料按鈕
              FilledButton.icon(
                onPressed: () {
                  // 這個按鈕的邏輯與主題 Provider 無關
                  ToastUtils.showShortToast(context, '還沒完成');
                },
                icon: const Icon(Icons.delete),
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                label: Text(
                  '清除資料',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          margin: const EdgeInsets.all(10),
          child: Center(
            child: RichText(
              // 使用 RichText 來混合不同風格的文字
              text: TextSpan(
                // RichText 的根節點是一個 TextSpan
                style: Theme.of(context).textTheme.titleMedium, // 使用主題文字風格
                children: <TextSpan>[
                  TextSpan(text: '本APP是模仿', style: Theme.of(context).textTheme.titleMedium),
                  // 連結部分的文字 TextSpan
                  TextSpan(
                    text: '這個網站',
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                      color: Colors.blue, // 連結顏色使用藍色
                      decoration: TextDecoration.underline, //底線
                    ),
                    // 設定手勢識別器，監聽點擊事件
                    // 呼叫 state 方法來打開 URL
                    recognizer:
                        TapGestureRecognizer()..onTap = () => _launchUrl(context), // 呼叫 state 方法
                  ),
                  TextSpan(
                    text: '製作的\n感謝該網站提供的資料 (･ω´･ )',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(),

        // --- 版本資訊 ---
        // _packageInfo 的更新通過 setState 觸發這個 Widget 重建
        // 所以包含 _packageInfo 的這個部分需要保留在這裡
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: AutoSizeText(
            'version： ${_packageInfo?.version ?? loadingMessage}',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
