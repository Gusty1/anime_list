import 'package:logger/logger.dart';

// 建立Logger 實例，這是第3方套件的 Logger，比較好看
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
  level: Level.debug, // 預設在 Debug 模式下設為 debug
);
