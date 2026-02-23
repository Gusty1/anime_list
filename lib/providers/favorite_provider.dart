import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/models/anime_item.dart';
import 'package:anime_list/providers/anime_database_provider.dart';
import 'package:anime_list/utils/date_helper.dart';
import 'package:anime_list/utils/logger.dart';

/// 管理收藏動漫列表的 AsyncNotifierProvider
///
/// 使用 [AsyncNotifier] 自動管理 loading / data / error 狀態，
/// 並提供搜尋、重新載入等方法。
/// 取代舊的 `FavoriteRefreshProvider`（bool toggle 機制）。
class FavoriteNotifier extends AsyncNotifier<List<AnimeItem>> {
  @override
  Future<List<AnimeItem>> build() async {
    return _fetchAll();
  }

  /// 取得所有收藏（由新到舊排序）
  Future<List<AnimeItem>> _fetchAll() async {
    final dbService = ref.read(animeDatabaseServiceProvider);
    final result = await dbService.getAllAnimeItems();

    // 依日期時間由新到舊排序
    result.sort(
      (a, b) => DateHelper.compareAnimeByDateTime(a, b, descending: true),
    );

    appLogger.d('FavoriteNotifier: 取得 ${result.length} 筆收藏');
    return result;
  }

  /// 根據關鍵字搜尋並更新 Provider 狀態
  Future<void> searchAndUpdate(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => search(query));
  }

  /// 根據關鍵字搜尋收藏
  Future<List<AnimeItem>> search(String query) async {
    final dbService = ref.read(animeDatabaseServiceProvider);
    List<AnimeItem> result;

    if (query.trim().isEmpty) {
      result = await dbService.getAllAnimeItems();
    } else {
      result = await dbService.searchAnimeItemsByName(query);
    }

    // 依日期時間由新到舊排序
    result.sort(
      (a, b) => DateHelper.compareAnimeByDateTime(a, b, descending: true),
    );

    return result;
  }

  /// 重新載入收藏列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAll());
  }
}

/// 收藏動漫列表的 Provider
final favoriteProvider =
    AsyncNotifierProvider<FavoriteNotifier, List<AnimeItem>>(
      () => FavoriteNotifier(),
    );
