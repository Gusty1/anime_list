import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/utils/logger.dart';

/// 管理當前選擇的動漫年月（例如 "2025.01"）的 Notifier
///
/// 當使用者在底部導航切換季番時，透過 [setYearMonth] 更新狀態，
/// 觸發 [animeListByYearMonthProvider] 重新載入對應資料。
class YearMonthNotifier extends Notifier<String> {
  @override
  String build() {
    appLogger.d('YearMonthNotifier: 初始化，預設狀態為空字串');
    return '';
  }

  /// 設定新的年月值
  void setYearMonth(String newYearMonth) {
    if (state != newYearMonth) {
      appLogger.d('YearMonthNotifier: 狀態更新為 $newYearMonth');
      state = newYearMonth;
    }
  }
}

/// 年月狀態的 NotifierProvider
final yearMonthProvider = NotifierProvider<YearMonthNotifier, String>(
  () => YearMonthNotifier(),
);
