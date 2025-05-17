import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// 使用第三套件的toast，安卓不能設定時間，只能設定顯示時間長短
class ToastUtils {
  // 私有建構子，防止外部實例化
  ToastUtils._();

  // --- 私有的輔助方法，用於實際呼叫 Fluttertoast.showToast ---
  // 這個方法接收所有需要的參數，包括從 context 獲取的顏色和字體大小
  static void _showToast(
    BuildContext context,
    String message,
    Toast toastLength,
    ToastGravity gravity,
    Color backgroundColor,
    Color textColor,
    double fontSize,
  ) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
    );
  }

  // --- 公共方法：顯示短時間的標準 Toast ---
  // 接收 BuildContext 來獲取主題顏色
  static void showShortToast(BuildContext context, String message) {
    // 從 BuildContext 獲取當前主題的配色方案和字體大小
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18;

    // 呼叫私有的輔助方法顯示 Toast
    _showToast(
      context,
      message,
      Toast.LENGTH_SHORT,
      // 設定為短時間
      ToastGravity.BOTTOM,
      // 設定在底部顯示
      colorScheme.primaryContainer,
      // 使用主題表面色作為背景
      colorScheme.primary,
      // 使用主題表面色的對比色作為文字顏色
      fontSize,
    );
  }

  //錯誤toast
  static void showShortToastError(BuildContext context, String message) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18;

    // 呼叫私有的輔助方法顯示 Toast
    _showToast(
      context,
      message,
      Toast.LENGTH_SHORT,
      ToastGravity.BOTTOM,
      colorScheme.errorContainer,
      colorScheme.error,
      fontSize,
    );
  }
}
