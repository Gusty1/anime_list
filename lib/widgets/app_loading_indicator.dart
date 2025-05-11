import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // 導入 flutter_spinkit 套件

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
    // 使用 Column 來垂直排列載入動畫和提示文字
    return Center(
      // 通常載入指示器會放在畫面中央
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 垂直置中
        crossAxisAlignment: CrossAxisAlignment.center, // 水平置中 (對於 Column 本身)
        mainAxisSize: MainAxisSize.min, // Column 盡可能小以包裹其子 Widget
        children: <Widget>[
          // *** 你選擇的 SpinKit 載入動畫 ***
          SpinKitWave(
            // 這裡以 SpinKitFadingCircle 為例，你可以換成其他類型
            color: Theme.of(context).colorScheme.primary,
            size: size,
            // 其他 SpinKit 特有的屬性可以在這裡設定
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
