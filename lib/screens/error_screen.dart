import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anime_list/constants.dart';

/// 錯誤頁面
///
/// 用於路由錯誤或其他未預期的錯誤情境，
/// 顯示錯誤訊息和返回首頁按鈕。
class ErrorScreen extends StatelessWidget {
  final dynamic error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('發生錯誤'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/errorRoute.gif'),
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                '應用程式發生錯誤:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go(homeRoute),
                child: const Text('回首頁'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
