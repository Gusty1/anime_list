import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/providers/router_provider.dart';
import 'package:anime_list/constants.dart';

/// 無網路連線頁面
///
/// 當 [ConnectivityWatcher] 偵測到網路中斷時，自動導航至此頁面。
/// 網路恢復後會自動返回原始頁面；使用者也可手動點擊「重新嘗試」主動觸發檢查。
class NoNetworkScreen extends ConsumerWidget {
  const NoNetworkScreen({super.key});

  /// 主動檢查網路狀態，若已恢復則導回首頁
  Future<void> _retry(WidgetRef ref) async {
    final results = await Connectivity().checkConnectivity();
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (hasNetwork) {
      ref.read(routerProvider).go(homeRoute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const SizedBox(height: 24),
              // 若 ConnectivityWatcher 偵測延遲，讓使用者可主動觸發重試
              ElevatedButton.icon(
                onPressed: () => _retry(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('重新嘗試'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
