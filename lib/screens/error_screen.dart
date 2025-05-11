import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants.dart';

// 這是一個簡單的 ErrorScreen Widget，用於在 errorBuilder 中顯示錯誤資訊
class ErrorScreen extends StatelessWidget {
  // 接收一個 dynamic 類型的 error 參數
  // dynamic 是因為錯誤的類型可能有多種 (Exception, Error, DioException 等)
  final dynamic error;

  // 構造函數，要求必須傳入 error 參數
  const ErrorScreen({
    super.key,
    required this.error, // 必須傳入 error
  });

  @override
  Widget build(BuildContext context) {
    // 你可以在這裡設計更複雜的錯誤畫面 UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('發生錯誤'),
        backgroundColor: Colors.redAccent, // 通常錯誤畫面使用醒目的顏色
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                '應用程式發生錯誤:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // 將 error 物件轉換為字串顯示
              Text(
                error.toString(), // 顯示錯誤的詳細資訊
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              // 你可以在這裡添加重試按鈕或其他操作
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  GoRouter.of(context).go(homeRoute);
                },
                child: const Text('回首頁'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}