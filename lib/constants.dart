// ---------------------------------------------------------------------------
// API 相關常數
// ---------------------------------------------------------------------------

/// 一言 API 網址（動漫類別，最大長度 100 字）
const String hitokotoApiUrl = 'https://v1.hitokoto.cn/?c=a&c=b&max_length=100';

/// API 請求逾時時間（秒），動漫資訊量大時需要較長時間
const int apiTimeout = 10;

/// ACG Taiwan Anime List 網站首頁
const String originUrl = 'https://acgntaiwan.github.io/Anime-List/';

/// 動漫資訊 JSON 的基底 URL（後接 YYYY.MM.json）
const String animeInfoBaseUrl =
    'https://gusty1.github.io/Database/anime_list/output/anime';

/// 動漫封面圖片的基底 URL
const String imageBaseUrl = 'https://acgntaiwan.github.io/Anime-List/';

/// MyAnimeList 網站（PV 來源）
const String malUrl = 'https://myanimelist.net/';

// ---------------------------------------------------------------------------
// 路由名稱常數
// ---------------------------------------------------------------------------

const String homeRoute = '/';
const String favoriteRoute = '/favorite';
const String settingsRoute = '/settings';
const String noNetwork = '/no-network';

// ---------------------------------------------------------------------------
// 字串常數
// ---------------------------------------------------------------------------

const String appTitle = 'Anime List';
const String favoriteTitle = '我的收藏';
const String settingsTitle = '設定';
const String loadingMessage = '載入中...';

// ---------------------------------------------------------------------------
// Email 相關常數
// ---------------------------------------------------------------------------

const String emailAddress = 'a0985209465@gmail.com';
const String emailSubject = 'Anime List 意見反饋';

// ---------------------------------------------------------------------------
// 數值常數
// ---------------------------------------------------------------------------

/// 動漫資料起始年份（ACG Taiwan 最早提供的年份）
const int startYear = 2018;
