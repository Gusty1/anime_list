import 'package:dio/dio.dart';
import '../models/hitokoto.dart';
import '../utils/logger.dart';
import '../constants.dart';
// import 'dart:developer' as developer; // AI說:雖然用了 logger，但保留 developer 導入以防萬一或作為對比

// api相關服務
class ApiService {
  final Dio _dio; // ApiService 依賴於 Dio 實例

  // 將 Dio 實例作為參數傳入 constructor (更利於測試)
  ApiService({required Dio dio}) : _dio = dio;

  // *** 添加獲取一言的方法 ***
  Future<Hitokoto?> fetchHitokoto() async {
    try {
      // GET 請求動漫名言 API
      final Response response = await _dio.get(hitokotoApiUrl);
      if (response.statusCode == 200) {
        // 檢查響應數據是否是 Map
        if (response.data is Map<String, dynamic>) {
          // 使用 Hitokoto.fromJson 解析響應數據
          return Hitokoto.fromJson(response.data as Map<String, dynamic>);
        } else {
          // 如果數據格式不符合預期，記錄警告
          appLogger.w('Unexpected response data format for Hitokoto: ${response.data}');
          return null;
        }
      } else {
        // 記錄非 200 狀態碼的錯誤
        appLogger.w('Error fetching Hitokoto: Status code ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      // 記錄 Dio 錯誤
      appLogger.e('Dio error during fetchHitokoto:', error: e);
      // 根據錯誤類型進行更精細的處理 (可選)
      return null;
    } catch (e) {
      // 記錄其他未知錯誤
      appLogger.e('Unexpected error during fetchHitokoto:', error: e);
      return null;
    }
  }
}
