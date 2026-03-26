import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
import 'package:anime_list/models/anime_item.dart';
import 'package:anime_list/providers/anime_list_provider.dart';
import 'package:anime_list/providers/year_month_provider.dart';
import 'package:anime_list/widgets/app_loading_indicator.dart';
import 'package:anime_list/utils/date_helper.dart';
import 'package:anime_list/widgets/anime/anime_list.dart';

/// 動畫清單頁面
///
/// 根據使用者選擇的年份載入動畫資料，
/// 透過星期 Tab 切換顯示不同天的動畫列表。
class AnimeListScreen extends ConsumerStatefulWidget {
  final String year;

  const AnimeListScreen({super.key, required this.year});

  @override
  ConsumerState<AnimeListScreen> createState() => _AnimeListScreenState();
}

class _AnimeListScreenState extends ConsumerState<AnimeListScreen> {
  int _currentTabIndex = 0;

  /// Tab 索引 (0=日, 1=一...) 到 DateTime.weekday 的映射
  static const List<int> _indexToWeekday = [
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  /// 7 個 Tab 的過濾結果快取，只在 animeList 改變時重新計算
  List<List<AnimeItem>>? _cachedFilteredLists;
  List<AnimeItem>? _lastAnimeList;

  @override
  void initState() {
    super.initState();
    // 在 Widget 第一次渲染完成後，設定 yearMonthProvider 的初始狀態
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final yearMonthNotifier = ref.read(yearMonthProvider.notifier);
      yearMonthNotifier.setYearMonth('${widget.year}.01');
    });
  }

  @override
  void didUpdateWidget(AnimeListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 年份切換時清除快取，確保下次 build 重新計算
    if (oldWidget.year != widget.year) {
      _cachedFilteredLists = null;
      _lastAnimeList = null;
    }
  }

  /// 根據最新的 [animeList] 計算並快取 7 個 Tab 的過濾結果
  ///
  /// 只在 [animeList] 參考改變時重新計算，避免每次 build 執行 7 次排序過濾。
  /// 呼叫點位於 build() 外部（[didUpdateWidget] 與首次資料抵達），
  /// 確保 build() 本身保持純函式特性。
  void _rebuildCache(List<AnimeItem> animeList) {
    _lastAnimeList = animeList;
    _cachedFilteredLists = List.generate(_indexToWeekday.length, (index) {
      return DateHelper.filterByWeekday(
        animeList,
        _indexToWeekday[index],
        widget.year,
      );
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final animeListAsyncValue = ref.watch(animeListByYearMonthProvider);

    const List<Widget> tabs = [
      Text('日'),
      Text('一'),
      Text('二'),
      Text('三'),
      Text('四'),
      Text('五'),
      Text('六'),
    ];

    return animeListAsyncValue.when(
      loading: () => const Center(child: AppLoadingIndicator()),
      data: (animeList) {
        if (animeList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sentiment_dissatisfied,
                  size: 64.0,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12.0),
                Text(
                  '查無資料',
                  style: TextStyle(
                    fontSize:
                        Theme.of(context).textTheme.titleLarge?.fontSize ?? 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        }

        // 只有在 animeList 參考改變時才重新計算快取，保持 build() 的純函式特性
        if (!identical(_lastAnimeList, animeList)) {
          _rebuildCache(animeList);
        }
        final filteredLists = _cachedFilteredLists!;

        return ContainedTabBarView(
          initialIndex: _currentTabIndex,
          onChange: _onTabChanged,
          tabs: tabs,
          views: List.generate(tabs.length, (index) {
            return AnimeList(animeList: filteredLists[index]);
          }),
          tabBarProperties: TabBarProperties(
            background: Container(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelColor: Theme.of(context).colorScheme.primary,
            labelStyle: Theme.of(context).textTheme.titleLarge,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            unselectedLabelStyle: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      },
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 12),
            Text(
              '載入失敗',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // 讓使用者主動重試，避免只能靠切換 Tab 或重新進入頁面
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(animeListByYearMonthProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('重新載入'),
            ),
          ],
        ),
      ),
    );
  }
}
