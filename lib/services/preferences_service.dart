import 'package:flutter_riverpod/flutter_riverpod.dart'; // 引入 riverpod
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// 本地儲存的相關服務，我只用來記錄亮暗主題而已
class PreferenceKeys {
  static const String darkMode = 'dark_mode'; // boolean 暗色模式 Key
  // 你可以在這裡添加其他 preference Keys
}

class PreferencesService {
  late SharedPreferences _preferences;

  PreferencesService._privateConstructor();

  static final PreferencesService _instance = PreferencesService._privateConstructor();

  factory PreferencesService() {
    return _instance;
  }

  //初始化 SharedPreferences 實例，必須在應用程式啟動時異步呼叫此方法
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // --- 儲存 boolean 暗色模式設定 ---
  // 這個方法用於保存使用者在設定頁的選擇，或第一次啟動時保存系統設定
  Future<bool> setDarkMode(bool value) async {
    return await _preferences.setBool(PreferenceKeys.darkMode, value);
  }

  // --- 讀取 boolean 暗色模式設定 ---
  // 返回 bool?，如果 Key 不存在則為 null
  // 這個方法用於判斷是否已經有儲存過的偏好
  bool? getIsDarkMode() {
    return _preferences.getBool(PreferenceKeys.darkMode);
  }

  // --- 範例：其他資料型別的讀寫 ---
  Future<bool> setString(String key, String value) async {
    return await _preferences.setString(key, value);
  }

  String? getString(String key) {
    return _preferences.getString(key);
  }

  // ... 添加其他你需要的讀寫方法

  // --- 清空所有資料 ---
  // 這個方法在實際應用中可能用在登出等場景，用於重置所有使用者偏好
  Future<bool> clearAll() async {
    return await _preferences.clear();
  }
}

// 由於要跟riverpod配合使用，我們需要將 PreferencesService 包裝成 Provider
// 定義一個 Provider 來提供 PreferencesService 實例
// 我們將在 main 函數中初始化 PreferencesService 並覆蓋這個 Provider，
// 以確保 Notifier 拿到的是已經初始化好的服務實例。
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  // 在 ProviderScope 中被 overrideWithValue 覆蓋
  throw UnimplementedError('PreferencesService should be overridden in ProviderScope');
});
