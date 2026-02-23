import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Toast 顯示工具類
///
/// 封裝 Fluttertoast，提供統一的 Toast 樣式。
/// 背景使用 inverseSurface（深色背景搭淺色文字），確保對比度。
class ToastUtils {
  // 私有建構子，防止外部實例化
  ToastUtils._();

  /// 內部輔助方法
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

  /// 顯示一般 Toast（短時間）
  static void showShortToast(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize =
        Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;

    _showToast(
      context,
      message,
      Toast.LENGTH_SHORT,
      ToastGravity.BOTTOM,
      // 使用 inverseSurface 確保深色背景 + 淺色文字，對比度高
      colorScheme.inverseSurface,
      colorScheme.onInverseSurface,
      fontSize,
    );
  }

  /// 顯示錯誤 Toast（短時間）
  static void showShortToastError(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize =
        Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;

    _showToast(
      context,
      message,
      Toast.LENGTH_SHORT,
      ToastGravity.BOTTOM,
      // 錯誤 Toast 使用 error 背景 + onError 文字
      colorScheme.error,
      colorScheme.onError,
      fontSize,
    );
  }
}
