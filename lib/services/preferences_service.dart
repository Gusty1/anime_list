import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // --- 儲存 boolean 暗色模式設定 ---
  Future<bool> setDarkMode(bool value) async {
    return await _preferences.setBool(PreferenceKeys.darkMode, value);
  }

  // --- 讀取 boolean 暗色模式設定，並提供預設值 ---
  bool getBoolWithDefault(String key, bool defaultValue) {
    return _preferences.getBool(key) ?? defaultValue;
  }

  // --- 清空所有資料 ---
  Future<bool> clearAll() async {
    return await _preferences.clear();
  }

  // --- 範例：其他資料型別的讀寫 ---
  Future<bool> setString(String key, String value) async { return await _preferences.setString(key, value); }
  String? getString(String key) { return _preferences.getString(key); }
// ... 添加其他你需要的讀寫方法
}

// 定義一個 Provider 來提供 PreferencesService 實例
// 我們將在 main 函數中初始化 PreferencesService 並覆蓋這個 Provider，
// 以確保 Notifier 拿到的是已經初始化好的服務實例。
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  // 這裡不直接創建實例，而是在 ProviderScope 中被 overrideWithValue 覆蓋
  // 以提供 main 中異步初始化好的單例實例。
  throw UnimplementedError('PreferencesService should be overridden in ProviderScope');
});