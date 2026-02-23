import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/services/preferences_service.dart';
import 'package:anime_list/utils/logger.dart';

/// 管理「深色模式開關」的 Notifier
///
/// 初始化邏輯：
/// 1. 從 SharedPreferences 讀取已儲存的偏好
/// 2. 若無儲存值，則讀取系統亮度作為預設值並存回偏好
class ThemeNotifier extends Notifier<bool> {
  late final PreferencesService _prefsService;

  @override
  bool build() {
    _prefsService = ref.read(preferencesServiceProvider);

    // 嘗試從偏好設定讀取
    final bool? savedIsDarkMode = _prefsService.getIsDarkMode();

    if (savedIsDarkMode != null) {
      appLogger.d('載入儲存的暗色模式偏好: $savedIsDarkMode');
      return savedIsDarkMode;
    }

    // 首次啟動，讀取系統亮度設定
    final Brightness systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final bool systemIsDark = systemBrightness == Brightness.dark;

    // 非同步存回偏好（不等待完成）
    _prefsService
        .setDarkMode(systemIsDark)
        .then((_) {
          appLogger.d('首次載入，已使用系統設定 ($systemIsDark) 並儲存');
        })
        .catchError((error) {
          appLogger.e('首次載入偏好儲存失敗: $error');
        });

    return systemIsDark;
  }

  /// 切換深色模式並儲存偏好
  Future<void> setDarkMode(bool isDark) async {
    if (state != isDark) {
      state = isDark;
      await _prefsService.setDarkMode(isDark);
      appLogger.d('暗色模式已更新為: $isDark');
    }
  }
}

/// 深色模式狀態的 NotifierProvider
final themeNotifierProvider = NotifierProvider<ThemeNotifier, bool>(
  () => ThemeNotifier(),
);
