import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants.dart';

// 錯誤螢幕，其實我也只設定錯誤路由會進來而已，手機應該是不會進來，總之就是先定義一下
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
    return Scaffold(
      appBar: AppBar(title: const Text('發生錯誤'), backgroundColor: Colors.redAccent),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/errorRoute.gif'), //不知道放什麼，給他一張51121迷因圖
              Icon(Icons.error_outline, color: Colors.red, size: 60),
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
