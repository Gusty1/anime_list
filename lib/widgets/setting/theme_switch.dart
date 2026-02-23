import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/providers/theme_provider.dart';

/// 深色/淺色主題切換元件
///
/// 使用原生 [Switch.adaptive] 取代第三方 toggle_switch 套件，
/// 獨立為 ConsumerWidget 避免不必要的重建蔓延。
class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDarkModeEnabled = ref.watch(themeNotifierProvider);
    final ThemeData currentTheme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text('主題', style: currentTheme.textTheme.titleMedium),
          ),
          // 淺色模式圖示
          Icon(
            Icons.wb_sunny,
            color:
                isDarkModeEnabled
                    ? currentTheme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : currentTheme.colorScheme.primary,
          ),
          // 原生主題切換開關
          Switch.adaptive(
            value: isDarkModeEnabled,
            onChanged: (bool value) {
              ref.read(themeNotifierProvider.notifier).setDarkMode(value);
            },
            activeTrackColor: currentTheme.colorScheme.primary,
          ),
          // 深色模式圖示
          Icon(
            Icons.nightlight_round,
            color:
                isDarkModeEnabled
                    ? currentTheme.colorScheme.primary
                    : currentTheme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
