import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// 一個獨立的載入指示器 Widget
class AppLoadingIndicator extends StatelessWidget {
  final double size; // 載入指示器的大小
  final String? text; // 可選的提示文字，如果為 null 則不顯示文字

  const AppLoadingIndicator({
    super.key,
    this.size = 20.0, // 提供一個預設大小
    this.text, // 提示文字是可選的
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // 我選擇的 SpinKit 載入動畫 (wave)
          SpinKitWave(
            color: Theme.of(context).colorScheme.primary,
            size: Theme.of(context).textTheme.titleLarge?.fontSize ?? size,
          ),

          // 如果有提示文字，則顯示文字
          if (text != null) ...[
            // 使用 ... 展開，將 SizedBox 和 Text 添加到 children 列表中
            const SizedBox(width: 16), // 指示器和文字之間的間隔
            Text(
              text!, // 顯示提示文字 (非空斷言因為 text != null)
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
