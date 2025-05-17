import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';
import '../utils/logger.dart';

// 定義管理「是否啟用暗色模式」 boolean 狀態的 Notifier
// Notifier<bool> 表示這個 Notifier 管理的狀態是一個 bool 值
class ThemeNotifier extends Notifier<bool> {
  // 使用 late 關鍵字，表示這個變數會在 build 方法中被初始化
  late final PreferencesService _prefsService;

  @override
  // build 方法用於初始化 Notifier 的狀態，邏輯是：
  // 1. 嘗試從 SharedPreferences 讀取 boolean 偏好 (bool?)
  // 2. 如果讀到值 (非 null)，則使用該值作為初始狀態
  // 3. 如果讀不到值 (為 null)，表示是第一次載入偏好，則讀取系統亮度，將其作為初始狀態，並將其保存到 SharedPreferences
  bool build() {
    // 通過 ref 讀取 preferencesServiceProvider，獲取 PreferencesService 實例
    _prefsService = ref.read(preferencesServiceProvider);

    // 嘗試從偏好設定讀取 boolean 偏好 (bool?，可能為 null)
    bool? savedIsDarkMode = _prefsService.getIsDarkMode();

    // 根據讀取到的值決定初始狀態
    if (savedIsDarkMode != null) {
      // 如果讀到值 (非 null)，則使用儲存的偏好作為初始狀態
      appLogger.i("載入儲存的暗色模式偏好: $savedIsDarkMode"); // Log 檢查
      return savedIsDarkMode;
    } else {
      // 如果讀不到值 (為 null)，表示是第一次載入偏好
      // 獲取系統亮度
      final Brightness systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      // 判斷系統是否為暗色模式
      final bool systemIsDark = systemBrightness == Brightness.dark;

      // 將讀取到的系統亮度設定保存到 SharedPreferences，作為「預設」偏好
      // Note: build 方法是同步的，但 setDarkMode 是異步的。
      // 我們在這裡「觸發」異步保存，而不等待它完成，讓 build 方法可以立即返回。
      // 使用 .then() 處理可能的異步操作結果/錯誤。
      _prefsService
          .setDarkMode(systemIsDark)
          .then((_) {
            appLogger.i("第一次載入偏好為 null，已讀取系統設定 ($systemIsDark) 並保存");
          })
          .catchError((error) {
            appLogger.i("第一次載入偏好保存系統設定時出錯: $error");
          });

      // 返回讀取到的系統亮度設定作為初始狀態
      return systemIsDark;
    }
  }

  // 方法：設定暗色模式狀態並保存 boolean 偏好設定
  // 這個方法用於使用者在設定頁切換開關
  Future<void> setDarkMode(bool isDark) async {
    // 檢查新狀態是否與當前狀態不同
    if (state != isDark) {
      // 更新 boolean 狀態 (賦值給 state 屬性，Notifier 會自動通知監聽者)
      state = isDark;
      // 異步保存 boolean 偏好設定
      await _prefsService.setDarkMode(isDark);
      appLogger.i("暗色模式狀態已更新為: $isDark, 偏好已儲存");
    }
  }
}

// 定義 boolean 狀態的 NotifierProvider
final themeNotifierProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});
