import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

//無網路螢幕
class NoNetworkScreen extends StatelessWidget {
  const NoNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 80, color: Theme.of(context).colorScheme.error),
              SizedBox(height: 20),
              AutoSizeText(
                '無網路連接',
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              AutoSizeText(
                '請檢查您的網路連線後重試',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              // 可選：添加一個按鈕，使用者點擊時可以再次檢查網路或重試載入
              // 如果你在這裡需要使用 ref，請將本 Widget 改為 ConsumerWidget 或 ConsumerStatefulWidget
              // 例如：
              // ElevatedButton(
              //   onPressed: () {
              //     // 假設有一個讀取數據的 Provider，你可以 refresh 它
              //     // ref.refresh(someDataProvider);
              //     // 或者只是等待網路恢復，ConnectivityWatcher 會自動跳轉
              //   },
              //   child: const Text('重試'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
