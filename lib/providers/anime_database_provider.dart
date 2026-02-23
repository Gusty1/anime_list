import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/services/anime_database_service.dart';

/// 提供 AnimeDatabaseService 單例的 Provider
///
/// 所有需要存取收藏資料庫的 Widget/Provider 都應透過此 Provider 取得服務實例，
/// 而非直接呼叫 `AnimeDatabaseService()`，以保持依賴注入的一致性。
final animeDatabaseServiceProvider = Provider<AnimeDatabaseService>((ref) {
  return AnimeDatabaseService();
});
