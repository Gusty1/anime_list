import 'dart:io';
import 'package:flutter/material.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:typed_data'; // Uint8List 處理圖片用的
import '../constants.dart';
import './my_drawer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';
import '../../widgets/toast_utils.dart';

//螢幕之間共用的導覽列與左側抽屜
class MyScaffoldWrapper extends StatelessWidget {
  final String title; // 畫面的標題
  final Widget body; // 畫面的主要內容
  final Widget? bottomNavigationBar; //可選底部導覽列
  final Widget? floatingActionButton; //可選右下按鈕

  const MyScaffoldWrapper({
    super.key,
    required this.title,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  //把回饋含圖片，用郵件發送
  Future<void> handleFeedbackAndSendEmail({
    required UserFeedback feedback,
    required BuildContext context,
  }) async {
    String? attachmentPath; // 用於儲存成功創建的截圖臨時檔案路徑，如果失敗則為 null
    if (!context.mounted) return;

    try {
      // 處理截圖，使用 await 等待獲取截圖的位元組數據 (Uint8List)
      final Uint8List? screenshotBytes = await feedback.screenshot;

      if (screenshotBytes != null) {
        try {
          // 獲取系統提供的臨時目錄路徑
          final tempDir = await getTemporaryDirectory();
          // 創建一個帶有唯一名稱的臨時檔案路徑，使用時間戳確保檔案名不容易衝突
          final filePath = path.join(
            tempDir.path,
            '${DateTime.now().microsecondsSinceEpoch}_screenshot.png',
          );
          final file = File(filePath);

          // 將截圖的位元組數據非同步寫入到臨時檔案
          await file.writeAsBytes(screenshotBytes);
          attachmentPath = filePath; // 儲存臨時檔案的路徑
          appLogger.i('截圖已儲存至臨時檔案: $attachmentPath');
        } catch (e) {
          // 處理儲存截圖檔案過程中發生的錯誤
          appLogger.e('儲存截圖至臨時檔案時發生錯誤: $e');
          attachmentPath = null; // 如果儲存失敗，確保不將路徑用於附件
        }
      }

      // === 準備並發送郵件 ===
      final Email email = Email(
        body: feedback.text,
        subject: emailSubject,
        recipients: [emailAddress],
        // 如果成功獲取到 attachmentPath (即截圖儲存成功)，則將其添加到郵件附件列表
        attachmentPaths: attachmentPath != null ? [attachmentPath] : [],
        isHTML: false, // 指定郵件內容為純文字格式
      );

      // 非同步發送電子郵件。這個方法會開啟系統的郵件客戶端讓用戶確認發送。
      await FlutterEmailSender.send(email);
      appLogger.i('回饋郵件成功寄出！');
      ToastUtils.showShortToast(context, '回饋郵件成功寄出！');
    } catch (e) {
      // === 處理在準備或發送郵件時發生的任何錯誤 ===
      // 這可能包括沒有找到可用的郵件客戶端，或郵件客戶端處理失敗等。
      appLogger.e('寄送回饋郵件失敗: $e'); // 記錄錯誤日誌
      ToastUtils.showShortToastError(context, '寄送回饋郵件失敗');
    } finally {
      // === 清理臨時檔案 ===
      // 這個 finally 塊會在 try 或 catch 塊執行完畢後執行
      // 無論郵件發送成功或失敗，如果之前成功創建了臨時截圖檔案，都嘗試將其刪除以釋放儲存空間。
      if (attachmentPath != null && await File(attachmentPath).exists()) {
        try {
          await File(attachmentPath).delete();
          appLogger.i('臨時截圖檔案已刪除: $attachmentPath');
        } catch (e) {
          // 刪除失敗通常不影響主要功能，但可以記錄下來以便排查問題。
          appLogger.e('刪除臨時截圖檔案失敗: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        // 標題右邊設定feedback(bug)按鈕
        actions: <Widget>[
          IconButton(
            onPressed: () {
              BetterFeedback.of(context).show((UserFeedback feedback) async {
                handleFeedbackAndSendEmail(feedback: feedback, context: context);
              });
            },
            icon: Icon(Symbols.bug_report),
          ),
        ],
      ),
      drawer: MyDrawer(),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
