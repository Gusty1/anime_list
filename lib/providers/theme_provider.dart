import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart'; // 替換成你的檔案路徑

// preferencesServiceProvider 定義來自 preferences_service.dart

// 定義管理「是否啟用暗色模式」的 Notifier
// Notifier<bool> 表示這個 Notifier 管理的狀態是一個 bool 值
class ThemeNotifier extends Notifier<bool> {
  // <-- 狀態型別是 bool

  // 使用 late 關鍵字，表示這個變數會在 build 方法中被初始化
  late final PreferencesService _prefsService;

  @override
  // build 方法用於初始化 Notifier 的狀態，並可以訪問 ref
  bool build() {
    // <-- 返回型別是 bool
    // 通過 ref 讀取 preferencesServiceProvider，獲取 PreferencesService 實例
    _prefsService = ref.read(preferencesServiceProvider);

    // 使用 getBoolWithDefault 載入 boolean 偏好設定，如果沒有保存，預設為 false (亮色)
    // 這個值直接作為 Notifier 的初始狀態
    bool isDarkMode = _prefsService.getBoolWithDefault(
      PreferenceKeys.darkMode,
      false,
    );

    print("載入初始暗色模式偏好: $isDarkMode"); // Log 檢查
    // 返回初始的 boolean 狀態
    return isDarkMode;
  }

  // 方法：設定暗色模式狀態並保存 boolean 偏好設定
  Future<void> setDarkMode(bool isDark) async {
    // <-- 方法接收 bool
    // 檢查新狀態是否與當前狀態不同
    if (state != isDark) {
      // 更新 boolean 狀態 (賦值給 state 屬性，Notifier 會自動通知監聽者)
      state = isDark;
      // 異步保存 boolean 偏好設定
      await _prefsService.setDarkMode(isDark);
      print("暗色模式狀態已更新為: $isDark, 偏好已儲存"); // Log 檢查
    }
  }
}

// 定義 ThemeMode 的 NotifierProvider，狀態型別是 bool
final themeNotifierProvider = NotifierProvider<ThemeNotifier, bool>(() {
  // <-- Provider 狀態型別是 bool
  // NotifierProvider 的創建函數返回 ThemeNotifier 的實例
  return ThemeNotifier();
});
