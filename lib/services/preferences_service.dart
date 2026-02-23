import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// SharedPreferences 的 Key 常數
class PreferenceKeys {
  static const String darkMode = 'dark_mode';
}

/// 本地偏好設定服務
///
/// 使用單例模式確保全域只有一個實例。
/// 目前僅用於儲存深色/淺色主題偏好。
class PreferencesService {
  late SharedPreferences _preferences;

  PreferencesService._privateConstructor();

  static final PreferencesService _instance =
      PreferencesService._privateConstructor();

  factory PreferencesService() => _instance;

  /// 初始化 SharedPreferences，必須在 main() 中呼叫
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// 儲存深色模式設定
  Future<bool> setDarkMode(bool value) async {
    return await _preferences.setBool(PreferenceKeys.darkMode, value);
  }

  /// 讀取深色模式設定（未曾儲存時回傳 null）
  bool? getIsDarkMode() {
    return _preferences.getBool(PreferenceKeys.darkMode);
  }

  /// 清空所有偏好設定
  Future<bool> clearAll() async {
    return await _preferences.clear();
  }
}

/// PreferencesService 的 Provider
///
/// 在 main() 中透過 `overrideWithValue` 提供已初始化的實例。
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError(
    'PreferencesService should be overridden in ProviderScope',
  );
});
