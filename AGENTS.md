# AGENTS.md — Anime List Flutter App

> AI agent 操作指南。描述本專案的架構、慣例、禁忌操作與常見任務的正確流程。
> 撰寫於 2026-04-28，基於版本 1.3.1+15。

---

## 目錄

1. [專案概覽](#1-專案概覽)
2. [技術棧與關鍵依賴](#2-技術棧與關鍵依賴)
3. [目錄結構](#3-目錄結構)
4. [架構慣例](#4-架構慣例)
5. [重要設計決策（禁止更動）](#5-重要設計決策禁止更動)
6. [常見任務操作指南](#6-常見任務操作指南)
7. [已知技術債與開放問題](#7-已知技術債與開放問題)
8. [測試現況](#8-測試現況)

---

## 1. 專案概覽

**用途：** 台灣動漫季番查詢 App，資料源自 ACG Taiwan Anime List。
**平台：** Android（主要），Windows（次要）。
**語言：** Dart / Flutter，採 Material 3 設計語言，強制直向顯示。
**架構：** MVVM + Riverpod 3（`flutter_riverpod ^3.2.1`）。

---

## 2. 技術棧與關鍵依賴

| 套件 | 用途 |
|------|------|
| `flutter_riverpod ^3.2.1` | 狀態管理（AsyncNotifier / Provider） |
| `go_router ^17.1.0` | 宣告式路由 |
| `flex_color_scheme ^8.4.0` | Material 3 主題（aquaBlue scheme） |
| `dio ^5.9.1` | HTTP 客戶端 |
| `sqflite ^2.4.2` | 本地 SQLite 收藏資料庫（v2 schema） |
| `youtube_player_flutter ^9.1.3` | PV 播放（需 `YoutubePlayerBuilder` 包住 Scaffold） |
| `cached_network_image ^3.4.1` | 封面圖快取 |
| `feedback ^3.2.0` | 截圖回饋（ZhTwFeedbackLocalizations 在地化） |
| `connectivity_plus ^7.0.0` | 網路狀態（回傳 `List<ConnectivityResult>`） |
| `share_plus ^13.0.0` | 分享動漫資訊（ShareParams API） |
| `easy_image_viewer ^1.5.1` | 全螢幕封面圖檢視 |
| `url_launcher ^6.3.2` | 開啟官網 / MAL 連結 |
| `permission_handler ^12.0.1` | Android 儲存權限 |
| `image_gallery_saver_plus ^4.0.1` | 儲存封面圖至相簿 |

---

## 3. 目錄結構

```
lib/
├── constants.dart          全域常數（API URL、路由名稱、字串常數）
├── main.dart               App 入口、ProviderScope、navigatorKey 宣告
├── generated/assets.dart   自動生成的資源路徑（勿手動修改）
├── l10n/                   意見回饋本地化（ZhTwFeedbackLocalizations）
├── models/
│   ├── anime_item.dart     動漫資料模型（含 fromJson / fromMap / copyWith / == / hashCode）
│   └── hitokoto.dart       一言資料模型
├── providers/              Riverpod 狀態管理層
│   ├── anime_database_provider.dart   SQLite service provider（keepAlive: true）
│   ├── anime_list_provider.dart       依年月取得動漫列表
│   ├── api_provider.dart              DioClient / ApiService providers
│   ├── connectivity_provider.dart     網路狀態 Stream provider
│   ├── favorite_provider.dart         收藏列表 + favoritedNamesProvider（防 N+1）
│   ├── hitokoto_provider.dart         一言 API
│   ├── router_provider.dart           GoRouter instance
│   ├── theme_provider.dart            深色/淺色模式切換
│   └── year_month_provider.dart       目前選取的年.月字串
├── services/
│   ├── anime_database_service.dart    SQLite CRUD（v2 schema）
│   ├── api_service.dart               遠端 API fetch（Hitokoto / AnimeItem）
│   ├── dio_client.dart                Dio 實例建立（timeout = 10s）
│   ├── preferences_service.dart       SharedPreferences 封裝
│   └── update_checker.dart            GitHub Releases 更新檢查
├── screens/
│   ├── anime/
│   │   ├── anime_detail_screen.dart   動漫詳情（完整頁面，含 YT PV + 封面圖 + Chip）
│   │   ├── anime_list_screen.dart     季番列表（依星期分 Tab）
│   │   └── anime_main_screen.dart     首頁（年份選擇 + 一言）
│   ├── favorite/
│   │   └── favorite_main_screen.dart  收藏列表（搜尋 + SQLite）
│   ├── setting/
│   │   └── setting_main_screen.dart   設定（深色模式、App 版本、意見回饋）
│   ├── error_screen.dart              GoRouter errorBuilder 錯誤頁
│   └── no_network_screen.dart         無網路提示頁
├── utils/
│   ├── date_helper.dart               日期解析/排序/過濾工具（核心業務邏輯）
│   ├── image_save_utils.dart          封面圖儲存 / 分享工具（handleImageLongPress）
│   └── logger.dart                    全域 appLogger（Logger package）
└── widgets/
    ├── anime/
    │   ├── anime_bottom_bar.dart      底部季番月份導覽（NavigationBar，僅顯示 01/04/07/10）
    │   ├── anime_card.dart            動漫卡片（點擊進入詳情）
    │   ├── anime_list.dart            ListView 包裝
    │   ├── anime_sentence.dart        一言文字 Widget（Timer 輪播）
    │   └── year_list_card.dart        年份選擇卡片
    ├── favorite/
    │   └── refresh_btn.dart           收藏頁重新載入 FAB
    ├── app_loading_indicator.dart     載入動畫（flutter_spinkit）
    ├── connectivity_watcher.dart      網路斷線監聽（全域 navigatorKey）
    ├── my_drawer.dart                 側邊選單
    ├── my_scaffold_wrapper.dart       統一 Scaffold（AppBar + Drawer + 底部列）
    └── toast_utils.dart               Toast 工具（fluttertoast）
```

---

## 4. 架構慣例

### 4.1 依賴方向（嚴格遵守）

```
Models（leaf，不依賴任何 app 內部模組）
  ↑
Utils（依賴 Models）
  ↑
Services（依賴 Models）
  ↑
Providers（依賴 Services + Models + Utils）
  ↑
Screens / Widgets（依賴 Providers + Models）
```

**不允許：** Service 依賴 Provider；Widget 直接呼叫 Service；Model 依賴 Provider。

### 4.2 Riverpod 使用規則

- **AsyncNotifier** 用於有副作用的非同步狀態（收藏列表、動漫列表）
- **FutureProvider** 用於唯讀非同步資料（一言、更新檢查）
- **Provider** 用於衍生同步狀態（`favoritedNamesProvider`、`routerProvider`）
- `ref.invalidate(favoriteProvider)` 用於觸發收藏重新載入；勿直接操作 state
- `animeDatabaseServiceProvider` 標記 `keepAlive: true`，全程保持 SQLite 連線

### 4.3 SQLite Schema（v2）

表格：`anime_items`，欄位：`name（PK）, date, time, carrier, season, originalName, img, description, official, pv（nullable）`。
新增欄位時必須同時更新 `_onCreate`（新安裝）與 `_onUpgrade`（升版遷移），並遞增 `_dbVersion`。

### 4.4 Material 3 主題規範

- **禁止** 使用 `Colors.red`、`Colors.grey` 等硬編碼顏色
- 一律使用 `colorScheme.*`（如 `colorScheme.error`、`colorScheme.primary`）
- 字體大小一律使用 `textTheme.*`（如 `textTheme.labelSmall`）

### 4.5 網路狀態處理

`connectivity_plus 7.x` 的 `checkConnectivity()` 回傳 **`List<ConnectivityResult>`**（非單一值）。
判斷無網路必須用：

```dart
final hasNoNetwork = result.every((r) => r == ConnectivityResult.none);
```

---

## 5. 重要設計決策（禁止更動）

### 5.1 雙層網路檢查機制

`router_provider.dart` 的 `redirect`（啟動時執行一次）與 `connectivity_watcher.dart`（運行時 Stream 監聽）**刻意並存**。兩套機制各司其職，不可刪除任何一套。

### 5.2 YoutubePlayerBuilder 必須包住 Scaffold

`anime_detail_screen.dart` 中有 PV 時，`YoutubePlayerBuilder` 必須是最外層，包住整個 `Scaffold`。這是 `youtube_player_flutter` 全螢幕切換的技術需求，不可改為在 Scaffold body 內建立 player。

### 5.3 navigatorKey 全域宣告

`navigatorKey` 宣告於 `main.dart`，同時被 `router_provider.dart`（GoRouter）和 `connectivity_watcher.dart`（Dialog 跳轉）使用。不可移動至其他檔案，除非兩處 import 同步更新。

### 5.4 favoritedNamesProvider 防 N+1

`favoritedNamesProvider` 將收藏名稱快取為 `Set<String>`，供所有 `AnimeCard` 共用，避免每張卡片發出獨立 DB 查詢。禁止在 Widget 層直接查詢 DB 確認收藏狀態。

### 5.5 AnimeBottomBar 只顯示季番月份

底部導覽列固定顯示 01、04、07、10 月，這是設計決策（非 Bug）。若要支援特別篇月份需另行評估。

---

## 6. 常見任務操作指南

### 新增動漫資料欄位

1. `models/anime_item.dart`：新增欄位、更新 `fromJson`、`fromMap`、`toJson`、`toMap`、`copyWith`、`==`、`hashCode`
2. `services/anime_database_service.dart`：新增欄位常數、更新 `_onCreate`、新增 `_onUpgrade` case、遞增 `_dbVersion`

### 新增路由頁面

1. `constants.dart`：新增路由路徑常數
2. `providers/router_provider.dart`：新增 `GoRoute`
3. 建立對應 Screen Widget

### 修改主題色彩

只修改 `main.dart` 中的 `FlexScheme.aquaBlue`，不可在各 Widget 內硬編碼顏色。

### 更新 PV 播放邏輯

必須在 `anime_detail_screen.dart` 的 `_AnimeDetailScreenState` 內操作，並注意：
- `YoutubePlayerController` 在 `initState` 建立，在 `dispose` 釋放
- `_restoreSystemUI()` 需在 `dispose`、`onExitFullScreen`、返回鍵、`AppLifecycleState.resumed` 四處呼叫

### 新增 SQLite 操作

在 `AnimeDatabaseService` 新增方法，並透過 `animeDatabaseServiceProvider` 注入至 Provider 層，不可在 Widget/Screen 直接 `new AnimeDatabaseService()`。

---

## 7. 已知技術債與開放問題

| 優先 | 說明 |
|------|------|
| LOW | `update_checker.dart` 含 Play Store TODO 待決策 |
| LOW | `ConnectivityWatcher` 在快速斷線重連時可能堆疊多個 Dialog |
| LOW | `AnimeBottomBar` 無法瀏覽非季番月份（如特別篇 06） |
| LOW | 多處 `CachedNetworkImage` 缺少 `semanticLabel`（無障礙） |
| LOW | `FavoriteMainScreen` 的搜尋列可提取為獨立 `FavoriteSearchBar` Widget |
| LOW | `win32 ^6.0.0` / `win32_registry ^3.0.2` major 版本待升級 |

---

## 8. 測試現況

目前測試覆蓋率極低（< 5%），僅有 `test/widget_test.dart` 的基本煙霧測試。

**優先補測試的目標：**

1. `utils/date_helper.dart`：`parseAnimeDate`、`filterByWeekday`、`filterOther`、`compareAnimeByDateTime`
2. `services/anime_database_service.dart`：CRUD 操作、LIKE 搜尋、升版遷移
3. `providers/favorite_provider.dart`：loading / data / error 狀態

執行測試：
```bash
flutter test
```
