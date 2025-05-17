import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 不知到是不是最近才更新的，AI提供的方法不行，找到最近的文章說有改動，然後AI就重新產生變成這樣了
// 定義一個 StreamProvider 來監聽網路狀態的變化
// 根據遇到的錯誤與外部說法，假設 onConnectivityChanged 在此版本回傳 Stream<List<ConnectivityResult>>
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  // 取得原始的 Stream<List<ConnectivityResult>>
  final rawStream = Connectivity().onConnectivityChanged;

  // 使用 .map 將 Stream<List<ConnectivityResult>> 轉換為 Stream<ConnectivityResult>
  // 對於 Stream 中的每個 List<ConnectivityResult> 事件 (results)，取出其第一個元素 (results.first)
  return rawStream.map((results) {
    // 通常情況下，List 中只有一個 ConnectivityResult，或者你需要根據邏輯處理多個的情況
    // 這裡假設我們只需要 List 中的第一個結果;
    if (results.isNotEmpty) {
      return results.first;
    }
    // 如果 List 為空 (理論上不應該發生，或者表示無連接？)
    // 你需要根據實際情況或 connectivity_plus 文件來決定如何處理空列表
    // 通常 ConnectivityResult.none 表示無連接，如果列表為空，可能也對應無連接
    // 這裡簡單處理，如果列表為空，回傳 none (需要引入 connectivity_plus/connectivity_plus.dart 中的 ConnectivityResult)
    return ConnectivityResult.none;
  });
});
