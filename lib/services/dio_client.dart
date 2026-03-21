import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:anime_list/constants.dart';
import 'package:anime_list/utils/logger.dart';

// 網路請求工具dio的設定
class DioClient {
  late Dio _dio; // 使用 late 修飾符，表示會在建構時初始化

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: apiTimeout), // 從 constants 讀取
        receiveTimeout: const Duration(seconds: apiTimeout), // 從 constants 讀取
        responseType: ResponseType.json,
        // baseUrl: 'https://your-api-base-url.com/', // 可選：在這裡設定基礎 URL
      ),
    );

    // Debug 模式下才加入詳細日誌攔截器，Release 模式完全跳過，避免字串序列化開銷
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (
            RequestOptions options,
            RequestInterceptorHandler handler,
          ) {
            appLogger.i('┌────── Dio Request ──────');
            appLogger.i('│ Method: ${options.method}');
            appLogger.i('│ URL: ${options.uri}');
            appLogger.i('│ Headers: ${options.headers}');
            if (options.data != null) {
              if (options.data is FormData) {
                appLogger.d('│ Data: FormData (包含文件)');
              } else {
                appLogger.d('│ Data: ${options.data}');
              }
            }
            appLogger.i('└─────────────────────────');
            return handler.next(options);
          },
          onResponse: (
            Response<dynamic> response,
            ResponseInterceptorHandler handler,
          ) {
            appLogger.i('┌────── Dio Response ──────');
            appLogger.i('│ Status Code: ${response.statusCode}');
            if (response.data != null &&
                response.data.toString().length < 1000) {
              appLogger.i('│ Data: ${response.data}');
            } else {
              appLogger.i('│ Data: (數據過大或為空)');
            }
            appLogger.i('└──────────────────────────');
            return handler.next(response);
          },
          onError: (DioException e, ErrorInterceptorHandler handler) {
            appLogger.e('┌────── Dio Error ──────');
            appLogger.e('│ Type: ${e.type}');
            appLogger.e('│ Message: ${e.message}');
            appLogger.e('│ Path: ${e.requestOptions.uri}');
            if (e.response != null) {
              appLogger.e('│ Response Status: ${e.response?.statusCode}');
              if (e.response?.data != null &&
                  e.response!.data.toString().length < 1000) {
                appLogger.e('│ Response Data: ${e.response?.data}');
              } else {
                appLogger.e('│ Response Data: (數據過大或為空)');
              }
            }
            appLogger.e('└─────────────────────');
            return handler.next(e);
          },
        ),
      );
    }
  }

  // 提供 Dio 實例的 getter
  Dio get dio => _dio;

  // 可選：如果你需要在應用程式關閉時關閉 Dio (雖然通常不強制，但對於某些場景可能有用)
  void close({bool force = false}) {
    _dio.close(force: force);
    appLogger.i('Dio client closed');
  }
}
