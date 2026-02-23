import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
import 'package:anime_list/providers/anime_list_provider.dart';
import 'package:anime_list/providers/year_month_provider.dart';
import 'package:anime_list/widgets/app_loading_indicator.dart';
import 'package:anime_list/screens/error_screen.dart';
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
  final List<int> _indexToWeekday = [
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  @override
  void initState() {
    super.initState();
    // 在 Widget 第一次渲染完成後，設定 yearMonthProvider 的初始狀態
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final yearMonthNotifier = ref.read(yearMonthProvider.notifier);
      yearMonthNotifier.setYearMonth('${widget.year}.01');
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

        return ContainedTabBarView(
          initialIndex: _currentTabIndex,
          onChange: _onTabChanged,
          tabs: tabs,
          views: List.generate(tabs.length, (index) {
            final weekday = _indexToWeekday[index];
            // 使用 DateHelper 集中的過濾與排序邏輯
            final filteredList = DateHelper.filterByWeekday(
              animeList,
              weekday,
              widget.year,
            );
            return AnimeList(animeList: filteredList);
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
      error: (err, stack) => Center(child: ErrorScreen(error: err.toString())),
    );
  }
}
