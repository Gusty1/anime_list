// API 相關常數
const String hitokotoApiUrl = 'https://v1.hitokoto.cn/?c=a&c=b&max_length=100'; // 不同於主要baseUrl的API
const int apiTimeout = 3; // API 請求逾時時間(秒)

// 路由名稱常數 (如果使用具名路由或 go_router path)
const String homeRoute = '/';
const String favoriteRoute = '/favorite';
const String settingsRoute = '/settings';
// 範例：帶參數的路由格式 (使用時需要替換參數部分)
// const String userDetailsRouteFormat = '/users/:userId';


// UI 或樣式相關常數
const double defaultPadding = 16.0; // 預設內外邊距大小
const double buttonHeight = 48.0; // 按鈕預設高度
const double cardElevation = 4.0; // 卡片的陰影高度

// 字串常數
const String appTitle = 'Anime List';
const String favoriteTitle = '我的收藏';
const String settingsTitle = '設定';
const String loadingMessage = '載入中...';
const String errorMessageGeneric = '發生未知錯誤，請稍後再試。';


// 其他類型的常數
// const int maxItemsPerPage = 10; // 每頁最大項目數
// const bool enableFeatureX = true; // 是否啟用某個功能