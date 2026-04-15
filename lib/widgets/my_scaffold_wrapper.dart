import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:anime_list/constants.dart';
import 'package:anime_list/widgets/my_drawer.dart';
import 'package:anime_list/utils/logger.dart';
import 'package:anime_list/widgets/toast_utils.dart';

/// 通用頁面骨架封裝
///
/// 提供一致的 AppBar（含回饋按鈕）、左側 Drawer 導航，
/// 以及可選的底部導覽列和浮動按鈕。
class MyScaffoldWrapper extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const MyScaffoldWrapper({
    super.key,
    required this.title,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  /// 處理使用者回饋，透過電子郵件發送
  Future<void> _sendFeedbackByEmail({
    required UserFeedback feedback,
    required BuildContext context,
  }) async {
    if (!context.mounted) return;

    String? attachmentPath;

    try {
      // 儲存截圖到暫存檔案
      if (feedback.screenshot.isNotEmpty) {
        attachmentPath = await _createScreenshotFile(feedback.screenshot);
      }

      final email = Email(
        body: feedback.text,
        subject: emailSubject,
        recipients: [emailAddress],
        attachmentPaths: attachmentPath != null ? [attachmentPath] : [],
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
      appLogger.d('回饋郵件已轉交郵件客戶端');

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

  /// 將截圖寫入暫存檔案
  Future<String?> _createScreenshotFile(Uint8List screenshotBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(
        tempDir.path,
        'feedback_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      final file = File(filePath);
      await file.writeAsBytes(screenshotBytes);
      appLogger.d('截圖已儲存至暫存檔案: $filePath');
      return filePath;
    } catch (e) {
      appLogger.e('儲存截圖至暫存檔案時發生錯誤: $e');
      return null;
    }
  }

  /// 刪除暫存截圖檔案
  Future<void> _deleteTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        appLogger.d('暫存截圖檔案已刪除: $filePath');
      }
    } catch (e) {
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
        actions: <Widget>[
          // 回饋按鈕
          IconButton(
            onPressed: () {
              BetterFeedback.of(context).show((UserFeedback feedback) {
                _sendFeedbackByEmail(feedback: feedback, context: context);
              });
            },
            icon: const Icon(Icons.bug_report),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
