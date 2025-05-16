import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// 使用第三套件的toast，安卓不能設定時間，只能設定顯示時間長短
class ToastUtils {
  // 私有建構子，防止外部實例化
  ToastUtils._();

  // --- 私有的輔助方法，用於實際呼叫 Fluttertoast.showToast ---
  // 這個方法接收所有需要的參數，包括從 context 獲取的顏色和字體大小
  static void _showToast(
      BuildContext context, // 依然需要 context 來獲取主題資訊
      String message,
      Toast toastLength,
      ToastGravity gravity,
      Color backgroundColor,
      Color textColor,
      double fontSize,
      ) {
    // 在非同步操作後呼叫此方法前，應確保 Widget 仍然 mounted，防止使用無效 context
    // 然而，ToastUtils 是靜態方法，無法直接訪問 Widget 的 mounted 狀態
    // 所以，呼叫者 (例如你的 Widget 中的異步方法) 負責在呼叫 ToastUtils 前檢查 mounted

    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
      // timeInSecForIosWeb: ... // 如果需要，可以作為參數傳入或在外部方法中指定
    );
  }

  // --- 公共方法：顯示短時間的標準 Toast ---
  // 接收 BuildContext 來獲取主題顏色
  static void showShortToast(BuildContext context, String message) {
    // 從 BuildContext 獲取當前主題的配色方案和字體大小
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18; // 調整預設字體大小為 16

    // 呼叫私有的輔助方法顯示 Toast
    _showToast(
      context,
      message,
      Toast.LENGTH_SHORT, // 設定為短時間
      ToastGravity.BOTTOM, // 設定在底部顯示
      colorScheme.primaryContainer, // 使用主題表面色作為背景
      colorScheme.primary, // 使用主題表面色的對比色作為文字顏色
      fontSize,
    );
  }

  //錯誤toast
  static void showShortToastError(BuildContext context, String message) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18; // 調整預設字體大小為 16

    // 呼叫私有的輔助方法顯示 Toast
    _showToast(
      context,
      message,
      Toast.LENGTH_SHORT, // 設定為短時間
      ToastGravity.BOTTOM, // 設定在底部顯示
      colorScheme.errorContainer, // 使用主題表面色作為背景
      colorScheme.error, // 使用主題表面色的對比色作為文字顏色
      fontSize,
    );
  }

  // --- 公共方法：顯示長時間或自訂樣式的 Toast ---
  // 接收 BuildContext 來獲取主題顏色
  static void showStyledToast(BuildContext context, String message) {
    // 從 BuildContext 獲取當前主題的配色方案和字體大小
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18; // 使用 bodyLarge 或其他需要的字體大小

    // 呼叫私有的輔助方法顯示 Toast
    _showToast(
      context,
      message,
      Toast.LENGTH_LONG, // <-- 修改為長時間
      ToastGravity.CENTER, // <-- 修改為在中間顯示 (或 TOP 等)
      colorScheme.primaryContainer, // 使用主題主色容器色作為背景 (或其他顏色)
      colorScheme.onPrimaryContainer, // 使用主色容器色的對比色作為文字顏色 (或其他顏色)
      fontSize,
    );
  }
}