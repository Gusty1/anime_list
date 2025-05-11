import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

// 將 Widget 改為 ConsumerStatefulWidget 以使用 ref
class SettingMainScreen extends ConsumerStatefulWidget { // <-- ConsumerStatefulWidget 來自 flutter_riverpod
  const SettingMainScreen({super.key});

  @override
  ConsumerState<SettingMainScreen> createState() => _SettingMainScreenState(); // <-- ConsumerState 來自 flutter_riverpod
}

// 將 State 改為 ConsumerState
class _SettingMainScreenState extends ConsumerState<SettingMainScreen> { // <-- ConsumerState 來自 flutter_riverpod

  @override
  void initState() {
    super.initState();
    // initState 中可以使用 ref.read 讀取 provider 的當前值 (不會觸發重建)
    // 例如： final initialIsDarkMode = ref.read(themeNotifierProvider);
    // print("Setting screen initialized with isDarkMode: $initialIsDarkMode");
  }

  @override
  // build 方法接收一個 WidgetRef 參數 (通常簡寫為 ref)
  Widget build(BuildContext context) { // <-- build 方法簽名 (在 ConsumerState 中 build 不需要 WidgetRef 參數)
    // 在 build 方法中，使用 ref.watch 監聽 themeNotifierProvider 的 boolean 狀態
    // 當 boolean 狀態改變時，build 方法會重新執行，更新 UI (例如 ToggleSwitch 的位置和文字)
    final bool isDarkModeEnabled = ref.watch(themeNotifierProvider); // <-- 監聽 boolean 狀態

    // 根據 boolean 狀態決定 ToggleSwitch 的初始位置
    // 0 for Light, 1 for Dark
    final int initialToggleIndex = isDarkModeEnabled ? 1 : 0; // <-- 根據 boolean 狀態設定初始索引

    // 獲取當前實際應用的亮度，用於顯示文字 (這個會反映 Material App 實際應用的主題)
    final bool isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToggleSwitch(
              initialLabelIndex: initialToggleIndex, // <-- 使用 boolean 狀態決定初始索引
              totalSwitches: 2,
              labels: const ['Light', 'Dark'],
              onToggle: (index) {
                if (index != null) {
                  final bool selectIsDark = index == 1;
                  // 使用 ref.read 獲取 Notifier 實例 (只需讀取一次，不需要監聽 Notifier 本身)
                  // 然後呼叫 Notifier 的 setDarkMode 方法來改變 boolean 狀態並保存
                  // ref.read 來自 flutter_riverpod
                  ref.read(themeNotifierProvider.notifier).setDarkMode(selectIsDark); // <-- 呼叫 setDarkMode
                  // Riverpod 會自動處理因狀態改變而觸發的 UI 重建
                }
              },
            ),
            const SizedBox(height: 20),
            // 顯示從 Provider 讀取到的 boolean 狀態對應的模式
            Text(
              '選定的模式：${isDarkModeEnabled ? "暗色" : "亮色"}', // <-- 顯示 boolean 狀態對應的文字
              style: const TextStyle(fontSize: 18),
            ),
            // 顯示目前實際應用的主題亮度 (這個文字會隨著 ThemeNotifier 的狀態改變而更新，因為 Widget 會重建)
            Text(
              '目前實際主題亮度：${isCurrentlyDark ? "暗色" : "亮色"}',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}