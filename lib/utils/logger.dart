import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

// 建立Logger 實例，這是第3方套件的 Logger，比較好看
// Release 模式下只輸出 warning 以上等級，避免洩漏敏感資訊
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    // 不顯示堆疊追蹤
    errorMethodCount: 5,
    // 錯誤時顯示堆疊追蹤層數
    lineLength: 120,
    // 每行最大長度
    colors: true,
    // 啟用顏色
    printEmojis: true, // 啟用表情符號
    // dateTimeFormat: DateTimeFormat.none, // 不顯示時間戳記 (因為 dio 的攔截器已經有時間概念)
  ),
  level: kReleaseMode ? Level.warning : Level.debug,
);
