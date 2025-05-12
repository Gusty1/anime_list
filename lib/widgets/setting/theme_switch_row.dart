import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../providers/theme_provider.dart';

//第3方套件的開關，我用來做亮暗主題的切換，由於會跟狀態變化監聽，所以獨立出來，不然會連其他UI都一起刷新
class ThemeSwitchRow extends ConsumerWidget {
  const ThemeSwitchRow({super.key});

  @override
  // ConsumerWidget 的 build 方法接收 WidgetRef ref
  Widget build(BuildContext context, WidgetRef ref) {
    // 監聽 themeNotifierProvider 的狀態變化
    final bool isDarkModeEnabled = ref.watch(themeNotifierProvider);

    // 根據 boolean 狀態決定 ToggleSwitch 的初始位置
    final int initialToggleIndex = isDarkModeEnabled ? 1 : 0;

    // 從當前主題獲取顏色 (這個也會隨著主題變化而變化，因為這個 build 方法會重建)
    final ThemeData currentTheme = Theme.of(context);
    final ColorScheme colorScheme = currentTheme.colorScheme;
    final Color activeBgColor = colorScheme.primary; // 選中背景用主題主色
    final Color inactiveBgColor = colorScheme.surface; // 未選中背景用主題表面色
    final Color inactiveFgColor = colorScheme.onSurface; // 未選中前景用主題表面色對比色

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: AutoSizeText('主題', style: Theme.of(context).textTheme.titleMedium)),
          ToggleSwitch(
            activeBgColor: [activeBgColor, activeBgColor],
            inactiveBgColor: inactiveBgColor,
            inactiveFgColor: inactiveFgColor,
            initialLabelIndex: initialToggleIndex,
            totalSwitches: 2,
            //開關數量
            icons: const [Icons.wb_sunny, Icons.nightlight_round],
            labels: null,
            onToggle: (index) {
              //開關切換要做的事
              if (index != null) {
                final bool selectIsDark = index == 1;
                // 使用 ref.read 呼叫 Notifier 的方法
                ref.read(themeNotifierProvider.notifier).setDarkMode(selectIsDark);
              }
            },
          ),
        ],
      ),
    );
  }
}
