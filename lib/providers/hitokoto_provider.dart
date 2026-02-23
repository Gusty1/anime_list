import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/models/hitokoto.dart';
import 'package:anime_list/providers/api_provider.dart';
import 'package:anime_list/utils/logger.dart';

/// 使用 FutureProvider 管理一言（Hitokoto）的載入狀態
///
/// 透過 Riverpod 的 [AsyncValue] 自動處理 loading / data / error，
/// 不再需要在 Widget 中手動管理 `_isLoading` / `_errorMessage` 等狀態。
///
/// 呼叫 `ref.invalidate(hitokotoProvider)` 可以重新載入新的名言。
final hitokotoProvider = FutureProvider<Hitokoto?>((ref) async {
  final apiService = ref.read(apiServiceProvider);

  try {
    final result = await apiService.fetchHitokoto();
    appLogger.d('hitokotoProvider: 取得一言 - ${result?.hitokoto ?? "null"}');
    return result;
  } catch (e) {
    appLogger.e('hitokotoProvider: 取得一言失敗 - $e');
    return null;
  }
});
