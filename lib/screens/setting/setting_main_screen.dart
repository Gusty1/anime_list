import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart'; // 引入手勢識別器，用於 TextSpan 的點擊
import '../../constants.dart';
import '../../widgets/toast_utils.dart';
import '../../widgets/setting/theme_switch.dart';
import '../../services/anime_database_service.dart';

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
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  // 異步函數，開啟爸爸網址
  Future<void> _launchUrl(BuildContext context) async {
    if (!mounted) return;
    final Uri url = Uri.parse(originUrl);
    if (!await launchUrl(url)) {
      ToastUtils.showShortToast(context, '無法開啟連結');
    }
  }

  void _showAlertDialog(BuildContext context) {
    // showDialog 函數用於在當前畫面上顯示一個對話框或彈出視窗
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確定清除'),
          content: const Text('所有收藏的動漫都會被清除，確定繼續?'),
          // actions 屬性：設定對話框底部的一系列操作按鈕，通常是一個 Widget 列表 這些按鈕通常靠右對齊
          actions: <Widget>[
            ElevatedButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // 這是一個 TextButton，點擊它來關閉對話框
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                if (!mounted) return;
                final dbService = AnimeDatabaseService();
                await dbService.clearAllAnimeItems();
                ToastUtils.showShortToast(context, '清除成功');
                Navigator.of(context).pop();
              },
              child: const Text('確定'),
            ),
          ],

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          // 設定對話框形狀 (例如圓角)
          backgroundColor: Theme.of(context).colorScheme.surface,
          // 設定對話框的背景顏色
          elevation: 5.0,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      // 使用 ListView 可以避免內容溢出
      children: [
        // 主題開關
        const ThemeSwitch(),
        const Divider(),
        // --- 意見回饋和清除資料按鈕 ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          margin: const EdgeInsets.all(10),
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () {
              _showAlertDialog(context);
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
