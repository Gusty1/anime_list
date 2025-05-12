import 'package:dio/dio.dart';
import '../constants.dart';
import '../utils/logger.dart';

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

    // 添加攔截器，使用 appLogger 進行日誌記錄
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          appLogger.i('┌────── Dio Request ──────');
          appLogger.i('│ Method: ${options.method}');
          appLogger.i('│ URL: ${options.uri}');
          appLogger.i('│ Headers: ${options.headers}');
          if (options.data != null) {
            // 檢查是否是 FormData，FormData 不需要打印整個 content
            if (options.data is FormData) {
              appLogger.d('│ Data: FormData (包含文件)');
            } else {
              appLogger.d('│ Data: ${options.data}');
            }
          }
          appLogger.i('└─────────────────────────');
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          appLogger.i('┌────── Dio Response ──────');
          appLogger.i('│ Status Code: ${response.statusCode}');
          // 避免打印過大的響應數據，特別是在生產環境
          if (response.data != null && response.data.toString().length < 1000) {
            // 限制打印長度
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
            // 錯誤響應數據，也避免打印過大
            if (e.response?.data != null && e.response!.data.toString().length < 1000) {
              appLogger.e('│ Response Data: ${e.response?.data}');
            } else {
              appLogger.e('│ Response Data: (數據過大或為空)');
            }
          }
          appLogger.e('└─────────────────────');

          // 可以根據錯誤類型或狀態碼決定是否繼續處理錯誤
          return handler.next(e); // 繼續處理錯誤，或根據需要 resolve/reject
        },
      ),
    );
  }

  // 提供 Dio 實例的 getter
  Dio get dio => _dio;

  // 可選：如果你需要在應用程式關閉時關閉 Dio (雖然通常不強制，但對於某些場景可能有用)
  void close({bool force = false}) {
    _dio.close(force: force);
    appLogger.i("Dio client closed");
  }
}
