import 'package:dio/dio.dart';
import 'package:logger/logger.dart'; // 導入 logger 套件
import '../constants.dart';

// 建立一個 Logger 實例
// 你可以根據需要配置不同的輸出格式、過濾級別等
var appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // 不顯示堆疊追蹤
    errorMethodCount: 5, // 錯誤時顯示堆疊追蹤層數
    lineLength: 120, // 每行最大長度
    colors: true, // 啟用顏色
    printEmojis: true, // 啟用表情符號
      dateTimeFormat: DateTimeFormat.none, // 不顯示時間戳記 (因為 dio 的攔截器已經有時間概念)
  ),
);


class DioClient {
  late Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: apiTimeout),
        receiveTimeout: const Duration(seconds: apiTimeout),
        responseType: ResponseType.json,
      ),
    );

    // 添加攔截器，使用 appLogger 進行日誌記錄
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          // 使用 logger.i (Info 級別) 記錄請求資訊
          appLogger.i('┌────── Dio Request ──────');
          appLogger.i('│ Method: ${options.method}');
          appLogger.i('│ URL: ${options.uri}');
          appLogger.i('│ Headers: ${options.headers}');
          if (options.data != null) {
            // 對於 POST/PUT 等請求的數據，可以使用 logger.d (Debug 級別) 或根據敏感度調整
            appLogger.d('│ Data: ${options.data}');
          }
          appLogger.i('└─────────────────────────');
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          // 使用 logger.i (Info 級別) 記錄響應資訊
          appLogger.i('┌────── Dio Response ──────');
          appLogger.i('│ Status Code: ${response.statusCode}');
          // 響應數據可能很大，可以考慮只在 Debug 或 Development 環境下詳細記錄
          appLogger.i('│ Data: ${response.data}');
          appLogger.i('└──────────────────────────');
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          // 使用 logger.e (Error 級別) 記錄錯誤資訊
          appLogger.e('┌────── Dio Error ──────');
          appLogger.e('│ Type: ${e.type}');
          appLogger.e('│ Message: ${e.message}');
          appLogger.e('│ Path: ${e.requestOptions.uri}');
          if(e.response != null){
            appLogger.e('│ Response Status: ${e.response?.statusCode}');
            // 錯誤響應數據，通常也很有用，可以使用 logger.e 記錄
            appLogger.e('│ Response Data: ${e.response?.data}');
          }
          // 可以在這裡記錄錯誤的堆疊追蹤，但 logger.e 預設就會包含
          // appLogger.e('│ Stacktrace:', e.stackTrace); // logger.e 通常會自動處理
          appLogger.e('└─────────────────────');

          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}