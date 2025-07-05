import 'dart:io';
import 'dart:typed_data'; // 用於處理 Uint8List 圖片資料
import 'package:flutter/material.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../constants.dart';
import './my_drawer.dart';
import '../utils/logger.dart';
import '../../widgets/toast_utils.dart';

// 提供一個包含 AppBar、抽屜和回饋按鈕的通用頁面結構
class MyScaffoldWrapper extends StatelessWidget {
  final String title; // 畫面的標題
  final Widget body; // 畫面的主要內容
  final Widget? bottomNavigationBar; // (可選) 底部導覽列
  final Widget? floatingActionButton; // (可選) 浮動操作按鈕

  const MyScaffoldWrapper({
    super.key,
    required this.title,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  // 處理使用者回饋，並透過電子郵件發送
  // 將主要邏輯拆分，提高可讀性和可維護性
  Future<void> _sendFeedbackByEmail({
    required UserFeedback feedback,
    required BuildContext context,
  }) async {
    // 在異步操作開始前先檢查 context 是否仍掛載在畫面上
    if (!context.mounted) return;

    String? attachmentPath; // 儲存截圖的暫存檔案路徑

    try {
      // 如果有截圖，則創建暫存檔案
      if (feedback.screenshot.isNotEmpty) {
        attachmentPath = await _createScreenshotFile(feedback.screenshot);
      }

      // 準備並發送郵件
      final Email email = Email(
        body: feedback.text, // 使用者輸入的文字
        subject: emailSubject, // 從 constants.dart 來的郵件主旨
        recipients: [emailAddress], // 從 constants.dart 來的收件人
        // 如果成功創建了截圖檔案，就將其路徑加入附件
        attachmentPaths: attachmentPath != null ? [attachmentPath] : [],
        isHTML: false, // 郵件內容為純文字
      );

      // 呼叫 flutter_email_sender 套件，開啟郵件 App
      await FlutterEmailSender.send(email);
      appLogger.i('回饋郵件已轉交郵件客戶端。');

      // 發送成功後，如果 context 仍然有效，則顯示提示
      if (context.mounted) {
        ToastUtils.showShortToast(context, '回饋郵件成功寄出！');
      }
    } catch (e, stackTrace) {
      appLogger.e('寄送回饋郵件失敗', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ToastUtils.showShortToastError(context, '寄送回饋郵件失敗');
      }
    } finally {
      if (attachmentPath != null) {
        await _deleteTempFile(attachmentPath);
      }
    }
  }

  // 私有輔助函式：將截圖數據寫入暫存檔
  Future<String?> _createScreenshotFile(Uint8List screenshotBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      // 使用時間戳確保檔案名稱的唯一性
      final filePath = path.join(
        tempDir.path,
        'feedback_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      final file = File(filePath);
      await file.writeAsBytes(screenshotBytes);
      appLogger.i('截圖已儲存至暫存檔案: $filePath');
      return filePath;
    } catch (e) {
      appLogger.e('儲存截圖至暫存檔案時發生錯誤: $e');
      return null; // 發生錯誤時返回 null
    }
  }

  // 私有輔助函式：刪除指定的暫存檔案
  Future<void> _deleteTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        appLogger.i('暫存截圖檔案已刪除: $filePath');
      }
    } catch (e) {
      // 即使刪除失敗，也只是記錄日誌，不影響使用者操作
      appLogger.w('刪除暫存截圖檔案失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        // 標題右側放置回饋 (bug report) 按鈕
        actions: <Widget>[
          IconButton(
            onPressed: () {
              // 顯示回饋視窗，並將使用者輸入的結果傳遞給我們的處理函式
              BetterFeedback.of(context).show((UserFeedback feedback) {
                // 不需要 async，因為 _sendFeedbackByEmail 本身就是 Future
                _sendFeedbackByEmail(feedback: feedback, context: context);
              });
            },
            icon: const Icon(Symbols.bug_report),
          ),
        ],
      ),
      drawer: const MyDrawer(), // 建議加上 const
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}