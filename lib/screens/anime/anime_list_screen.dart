import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../providers/api_provider.dart';
import '../../providers/year_month_provider.dart';
import '../../models/anime_item.dart';
import '../../widgets/app_loading_indicator.dart';
import '../error_screen.dart';
import '../../utils/logger.dart';
import '../../widgets/anime/anime_list.dart';

// 監測年月依賴改變的方法，好像是因為我的回傳widget比較複雜，所以AI說只能這樣寫
final animeListByYearMonthProvider = FutureProvider<List<AnimeItem>>((ref) async {
  final currentYearMonth = ref.watch(yearMonthProvider);
  appLogger.i('animeListByYearMonthProvider: yearMonth 依賴改變或初始化，準備載入資料 for $currentYearMonth');

  if (currentYearMonth.isEmpty || currentYearMonth == '預設的初始年月') {
    // Use actual default
    appLogger.i('animeListByYearMonthProvider: 當前年月是空的，跳過載入。');
    return Future.value([]);
  }

  final apiService = ref.read(apiServiceProvider);

  try {
    final List<AnimeItem>? animeList = await apiService.fetchAnimeInfoByYearMonth(currentYearMonth);
    appLogger.i(
      'animeListByYearMonthProvider: 獲取到 ${animeList?.length ?? 0} 筆資料 for $currentYearMonth。',
    );
    return animeList ?? [];
  } catch (e, stack) {
    appLogger.e(
      'animeListByYearMonthProvider: 載入資料 for $currentYearMonth 時發生錯誤: ${e.toString()}\n$stack',
    );
    throw Exception('載入動漫列表失敗 for $currentYearMonth: ${e.toString()}');
  }
});

class AnimeListScreen extends ConsumerStatefulWidget {
  // 保留 year 參數，因為它在 _filterAnimeListByWeekday 中使用
  final String year;

  const AnimeListScreen({super.key, required this.year});

  @override
  ConsumerState<AnimeListScreen> createState() => _AnimeListScreenState();
}

class _AnimeListScreenState extends ConsumerState<AnimeListScreen> {
  int _currentTabIndex = 0;

  // 協助列表：Tab 索引 (0=日, 1=一...) 到 DateTime.weekday 的映射
  final List<int> _indexToWeekday = [
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  // 協助函數：根據完整列表和目標星期幾過濾動漫項目
  // 使用 widget.year 來構建日期進行比較
  List<AnimeItem> _filterAnimeListByWeekday(List<AnimeItem> animeList, int weekday) {
    final filteredList =
        animeList.where((item) {
          try {
            final parts = item.date.split('/');
            if (parts.length != 2) return false;
            final month = int.parse(parts[0]);
            final day = int.parse(parts[1]);
            int yearInt;
            try {
              yearInt = int.parse(widget.year);
            } catch (e) {
              appLogger.e('錯誤: _filterAnimeListByWeekday 解析 widget.year "${widget.year}" 失敗 - $e');
              return false;
            }
            final date = DateTime(yearInt, month, day);
            return date.weekday == weekday;
          } catch (e) {
            appLogger.e(
              '錯誤: _filterAnimeListByWeekday ${item.name}的日期 "${item.date}" 或年份 "${widget.year}" 失敗 - ${e.toString()}',
            );
            return false;
          }
        }).toList();

    //日期舊到新排序
    filteredList.sort((a, b) {
      try {
        // 解析項目 a 的日期和時間
        final datePartsA = a.date.split('/');
        final monthA = int.parse(datePartsA[0]);
        final dayA = int.parse(datePartsA[1]);
        final timePartsA = a.time.split(':');
        final hourA = int.parse(timePartsA[0]);
        final minuteA = int.parse(timePartsA[1]);
        int yearIntA = int.parse(widget.year);
        final dateTimeA = DateTime(yearIntA, monthA, dayA, hourA, minuteA);

        // 解析項目 b 的日期和時間
        final datePartsB = b.date.split('/');
        final monthB = int.parse(datePartsB[0]);
        final dayB = int.parse(datePartsB[1]);
        final timePartsB = b.time.split(':');
        final hourB = int.parse(timePartsB[0]);
        final minuteB = int.parse(timePartsB[1]);
        int yearIntB = int.parse(widget.year);
        final dateTimeB = DateTime(yearIntB, monthB, dayB, hourB, minuteB);

        return dateTimeA.compareTo(dateTimeB);
      } catch (e) {
        // 理論上如果過濾函數正常工作，這裡不應該發生解析錯誤。
        // 作為防禦性編程，記錄錯誤並讓這兩個項目相對順序不定。
        appLogger.e('錯誤: Sort - 處理日期/時間 "${a.name} 錯誤") - ${e.toString()}');
        return 0; // 返回 0 表示相等，不改變相對順序
      }
    });

    return filteredList;
  }

  @override
  void initState() {
    super.initState();
    // 在 Widget 第一次渲染完成後，設定 yearMonthProvider 的初始狀態
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialYearMonthProvider(widget.year);
    });
  }

  // 協助函數：設定 yearMonthProvider 的初始狀態
  void _setInitialYearMonthProvider(String initialYear) {
    final yearMonthNotifier = ref.read(yearMonthProvider.notifier);
    // 初始載入該年份的冬番(1月)資料
    String initialYearMonth = '${widget.year}.01';
    yearMonthNotifier.setYearMonth(initialYearMonth);
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 FutureProvider 的狀態
    final animeListAsyncValue = ref.watch(animeListByYearMonthProvider);

    // Tab 標題 Widgets 列表 (對應日-六)
    final List<Widget> tabs = const [
      AutoSizeText('日'),
      AutoSizeText('一'),
      AutoSizeText('二'),
      AutoSizeText('三'),
      AutoSizeText('四'),
      AutoSizeText('五'),
      AutoSizeText('六'),
    ];

    // 使用 AsyncValue.when 來處理載入、資料、錯誤狀態
    return animeListAsyncValue.when(
      loading: () => const Center(child: AppLoadingIndicator()),
      data: (animeList) {
        if (animeList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.sentiment_dissatisfied,
                  size: 64.0,
                  color: Theme.of(context).colorScheme.error,
                ),
                SizedBox(height: 12.0),
                Text(
                  '查無資料',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        }
        return ContainedTabBarView(
          initialIndex: _currentTabIndex,
          onChange: _onTabChanged,
          tabs: tabs,
          // 使用 List.generate 為每個 星期Tab 創建一個 View
          views:
              List.generate(tabs.length, (index) {
                final viewWeekday = _indexToWeekday[index];
                final viewFilteredList = _filterAnimeListByWeekday(animeList, viewWeekday);
                return AnimeList(animeList: viewFilteredList);
              }).toList(),
          tabBarProperties: TabBarProperties(
            background: Container(color: Theme.of(context).colorScheme.inversePrimary),
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelColor: Theme.of(context).colorScheme.primary,
            labelStyle: Theme.of(context).textTheme.titleLarge,
            unselectedLabelColor: Theme.of(context).colorScheme.onInverseSurface,
          ),
        );
      },
      error: (err, stack) => Center(child: ErrorScreen(error: err.toString())),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
