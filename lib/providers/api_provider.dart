import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/services/dio_client.dart';
import 'package:anime_list/services/api_service.dart';

/// DioClient 的 Provider（全域單一實例）
///
/// DioClient 的建構子會自動完成 Dio 的配置（逾時、攔截器等）。
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// ApiService 的 Provider
///
/// 依賴 [dioClientProvider] 取得已配置好的 Dio 實例。
final apiServiceProvider = Provider<ApiService>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return ApiService(dio: dioClient.dio);
});
