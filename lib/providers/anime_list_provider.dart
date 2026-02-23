import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/models/anime_item.dart';
import 'package:anime_list/providers/api_provider.dart';
import 'package:anime_list/providers/year_month_provider.dart';
import 'package:anime_list/utils/logger.dart';

/// 根據當前選擇的年月，從 API 載入動漫列表的 FutureProvider
///
/// 會自動監聽 [yearMonthProvider] 的變化，當使用者切換季番時重新載入資料。
/// 使用 [AsyncValue] 自動管理 loading / data / error 三種狀態。
final animeListByYearMonthProvider = FutureProvider<List<AnimeItem>>((
  ref,
) async {
  final currentYearMonth = ref.watch(yearMonthProvider);

  if (currentYearMonth.isEmpty) {
    appLogger.d('animeListByYearMonthProvider: yearMonth 為空，跳過載入。');
    return [];
  }

  final apiService = ref.read(apiServiceProvider);

  try {
    final List<AnimeItem>? animeList = await apiService
        .fetchAnimeInfoByYearMonth(currentYearMonth);
    appLogger.d(
      'animeListByYearMonthProvider: 取得 ${animeList?.length ?? 0} 筆資料 ($currentYearMonth)',
    );
    return animeList ?? [];
  } catch (e, stack) {
    appLogger.e(
      'animeListByYearMonthProvider: 載入失敗 ($currentYearMonth): $e\n$stack',
    );
    throw Exception('載入動漫列表失敗 ($currentYearMonth): $e');
  }
});
