import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/services/anime_database_service.dart';

/// 提供 [AnimeDatabaseService] 實例的 Provider
///
/// 使用 `keepAlive: true` 確保資料庫連線在整個 App 生命週期內持續存在，
/// 取代原本在 [AnimeDatabaseService] 內部的靜態 Singleton 模式。
/// 所有需要存取收藏資料庫的 Widget/Provider 都應透過此 Provider 取得實例，
/// 方便測試時以 `overrideWithValue` 注入 mock。
final animeDatabaseServiceProvider = Provider<AnimeDatabaseService>((ref) {
  final service = AnimeDatabaseService();

  // keepAlive 確保資料庫連線在整個 App 生命週期內持續存在，
  // 替代原本在 AnimeDatabaseService 內部的靜態 Singleton
  ref.keepAlive();

  // App 結束時關閉資料庫連線並釋放資源
  ref.onDispose(service.close);

  return service;
});
