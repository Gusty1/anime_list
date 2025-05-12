import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dio_client.dart';
import '../services/api_service.dart';

// 因為需要riverpod來提供全局單一實例，所以建立這個provider
// DioClient 的建構子會負責創建和配置內部 Dio 實例並添加攔截器。
final dioClientProvider = Provider<DioClient>((ref) {
  // 直接創建並返回 DioClient 實例
  // DioClient 的建構子會自動完成 Dio 的配置
  final dioClient = DioClient();

  // 可選：如果 DioClient 有 close 方法且需要在 Provider 被 dispose 時關閉
  // ref.onDispose(() {
  //   dioClient.close();
  // });

  return dioClient;
});

// --- 提供 ApiService 實例的 Provider ---
// ApiService 依賴於 Dio 實例 (通過 DioClient 獲取)
final apiServiceProvider = Provider<ApiService>((ref) {
  // 使用 ref.read() 讀取 dioClientProvider，獲取 DioClient 實例
  final dioClient = ref.read(dioClientProvider);

  // 使用 DioClient 的 getter 獲取配置好的 Dio 實例
  final dio = dioClient.dio;

  // 使用獲取的 Dio 實例來創建 ApiService 實例
  // Provider 會緩存 ApiService 實例，確保全局只有一個
  return ApiService(dio: dio);
});