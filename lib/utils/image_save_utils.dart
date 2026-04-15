import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:typed_data';
import 'package:anime_list/utils/logger.dart';
import 'package:anime_list/widgets/toast_utils.dart';

/// 請求儲存圖片的權限（依 Android 版本使用不同的權限）
Future<bool> requestSavePermission() async {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  if (sdkInt >= 33) {
    // Android 13+ 使用 READ_MEDIA_IMAGES
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  } else {
    // Android 12 以下使用 STORAGE
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  }
}

/// 下載圖片並儲存到相簿（從快取讀取已下載的圖片）
Future<bool> downloadAndSaveImage(String imageUrl, String fileName) async {
  try {
    final file = await DefaultCacheManager().getSingleFile(imageUrl);
    final bytes = await file.readAsBytes();

    final result = await ImageGallerySaverPlus.saveImage(
      Uint8List.fromList(bytes),
      quality: 100,
      name: fileName,
    );

    if (result is Map) {
      return (result['isSuccess'] as bool?) ?? false;
    }
    return false;
  } catch (e) {
    appLogger.e('儲存圖片錯誤', error: e);
    return false;
  }
}

/// 處理圖片長按儲存邏輯
Future<void> handleImageLongPress(
  BuildContext context,
  String imageUrl,
  String animeName,
) async {
  final hasPermission = await requestSavePermission();
  if (!hasPermission) {
    if (!context.mounted) return;
    ToastUtils.showShortToastError(context, '儲存圖片失敗：未取得權限，請至應用程式設定開啟');
    return;
  }

  final fileName =
      'anime_${animeName}_${DateTime.now().millisecondsSinceEpoch}';
  final result = await downloadAndSaveImage(imageUrl, fileName);

  if (!context.mounted) return;
  if (result) {
    ToastUtils.showShortToast(context, '圖片已儲存到相簿');
  } else {
    ToastUtils.showShortToastError(context, '儲存失敗，請稍後再試');
  }
}
