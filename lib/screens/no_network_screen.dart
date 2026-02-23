import 'package:flutter/material.dart';

/// 無網路連線頁面
///
/// 當 [ConnectivityWatcher] 偵測到網路中斷時，自動導航至此頁面。
/// 網路恢復後會自動返回首頁。
class NoNetworkScreen extends StatelessWidget {
  const NoNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                '無網路連接',
                style: TextStyle(
                  fontSize:
                      Theme.of(context).textTheme.titleLarge?.fontSize ?? 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '請檢查您的網路連線狀態',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
