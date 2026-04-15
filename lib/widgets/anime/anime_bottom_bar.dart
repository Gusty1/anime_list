import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_list/providers/year_month_provider.dart';

/// 動畫清單頁面的底部季番導航列
///
/// 提供冬番/春番/夏番/秋番四個季番切換，
/// 切換時更新 [yearMonthProvider] 觸發資料重新載入。
class AnimeBottomBar extends ConsumerStatefulWidget {
  final String year;

  const AnimeBottomBar({super.key, required this.year});

  @override
  ConsumerState<AnimeBottomBar> createState() => _AnimeBottomBarState();
}

class _AnimeBottomBarState extends ConsumerState<AnimeBottomBar> {
  int _selectedIndex = 0;

  /// 季番月份對應表：[冬=01, 春=04, 夏=07, 秋=10]
  static const List<String> _seasonMonths = ['01', '04', '07', '10'];

  void _onItemTapped(int index) {
    if (!mounted) return;

    final yearMonthNotifier = ref.read(yearMonthProvider.notifier);
    final newYearMonth = '${widget.year}.${_seasonMonths[index]}';
    yearMonthNotifier.setYearMonth(newYearMonth);

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.ac_unit),
          label: '冬番',
        ),
        NavigationDestination(
          icon: Icon(Icons.spa),
          label: '春番',
        ),
        NavigationDestination(
          icon: Icon(Icons.beach_access),
          label: '夏番',
        ),
        NavigationDestination(
          icon: Icon(Icons.eco),
          label: '秋番',
        ),
      ],
    );
  }
}
