import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../providers/year_month_provider.dart';

// 動畫清單底部導航，使用第三方套件，由於內部有狀態，加上需要把參數傳到list screen，所以用riverpod
class AnimeBottomBar extends ConsumerStatefulWidget {
  final String year; // 首頁傳進來的年份參數

  const AnimeBottomBar({super.key, required this.year});

  @override
  ConsumerState<AnimeBottomBar> createState() => _AnimeBottomBarState();
}

class _AnimeBottomBarState extends ConsumerState<AnimeBottomBar> {
  // 定義並初始化選中項目的狀態變數 (這是 Widget 的內部狀態)
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  // 當底部導航項目被點擊時呼叫的方法
  void _onItemTapped(int index) {
    if (mounted == false) return;
    // 使用 ref.read() 因為我們只需要呼叫 Notifier 的方法，不需要在這個方法中監聽 Provider 的變化
    final yearMonthNotifier = ref.read(yearMonthProvider.notifier);

    // 根據點擊的索引和 Widget 傳入的年份參數，構建新的 yearMonth 字串
    String newYearMonth = '';
    String currentYear = widget.year;

    switch (index) {
      case 0:
        newYearMonth = '$currentYear.01';
        break;
      case 1:
        newYearMonth = '$currentYear.04';
        break;
      case 2:
        newYearMonth = '$currentYear.07';
        break;
      case 3:
        newYearMonth = '$currentYear.10';
        break;
      default:
        break;
    }

    // 呼叫 YearMonthNotifier 中定義的 setYearMonth 方法來更新 Provider 的狀態
    // 這會通知所有監聽 yearMonthProvider 的 Widget 或其他 Provider
    yearMonthNotifier.setYearMonth(newYearMonth);

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConvexAppBar(
      // 定義底部導航欄的項目列表
      items: const [
        TabItem(icon: Symbols.ac_unit, title: '冬番'),
        TabItem(icon: Symbols.nest_eco_leaf, title: '春番'),
        TabItem(icon: Symbols.beach_access, title: '夏番'),
        TabItem(icon: Symbols.cannabis, title: '秋番'),
      ],
      height: 60.0,
      // 使用狀態變數來設定初始選中的項目索引
      initialActiveIndex: _selectedIndex,
      // 將點擊事件連接到 _onItemTapped 方法
      onTap: _onItemTapped,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      activeColor: Theme.of(context).colorScheme.secondary,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  // 如果需要在 State 銷毀時做一些清理工作，可以覆寫 dispose() 方法
  @override
  void dispose() {
    // 例如：銷毀可能在這裡創建的控制器等
    super.dispose();
  }
}
