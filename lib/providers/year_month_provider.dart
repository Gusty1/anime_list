import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

// 定義動漫年月的狀態管理 單一 String 狀態的 Notifier
class YearMonthNotifier extends Notifier<String> {
  @override
  // build 方法用於初始化 Notifier 的狀態
  String build() {
    // 這裡設定初始狀態。
    // 注意：由於這是單一 Notifier，build() 在 Provider 第一次被讀取時執行。
    // 你無法直接在這裡從路由獲取 yearMonth 參數，因為 Provider 是獨立於 Widget Tree 定義的。
    appLogger.i('--- YearMonthNotifier build，設定預設初始狀態 ---');
    return ''; // 設定一個預設的初始狀態
  }

  // 添加方法來更新這個 Notifier 管理的 String 狀態
  // 你可以在獲取到路由參數後，從 Widget 中呼叫這個方法來設定狀態
  void setYearMonth(String newYearMonth) {
    if (state != newYearMonth) {
      appLogger.i('--- YearMonthNotifier 設定狀態為: $newYearMonth ---');
      // 通過賦值給 state 來更新狀態
      state = newYearMonth;
    }
  }
}

// 定義 標準的 NotifierProvider
// NotifierProvider<NotifierT, StateT> 的兩個類型參數：
// - NotifierT: Notifier 的類別 (YearMonthNotifier)
// - StateT: Notifier 管理的狀態類型 (String)
final yearMonthProvider = NotifierProvider<YearMonthNotifier, String>(
  // 這裡的工廠函數只需要返回 YearMonthNotifier 的實例即可
  () => YearMonthNotifier(),
);
