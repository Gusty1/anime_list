# 專案架構分析報告

> **生成日期：** 2026-03-25
> **最後更新：** 2026-04-15
> **專案版本：** 1.3.1+15
> **Flutter SDK：** ^3.7.0
> **分析範圍：** `lib/` 目錄全部 Dart 原始碼（排除 `.dart_tool/`）

---

## 目錄

1. [專案結構概覽](#1-專案結構概覽)
2. [架構模式評估](#2-架構模式評估)
3. [開放問題](#3-開放問題)
4. [相依性管理](#4-相依性管理)
5. [UI 元件設計](#5-ui-元件設計)
6. [未來建議](#6-未來建議)
7. [測試覆蓋率](#7-測試覆蓋率)
8. [總評](#8-總評)

---

## 1. 專案結構概覽

```
lib/
├── constants.dart          (52 行)  全域常數
├── main.dart               (112 行) App 進入點、Provider 範圍設定
├── generated/
│   └── assets.dart                  自動生成的資源路徑常數
├── l10n/
│   └── zh_tw_feedback_localizations.dart  意見回饋本地化
├── models/
│   ├── anime_item.dart     (182 行) 動漫資料模型
│   └── hitokoto.dart       (85 行)  一言資料模型
├── providers/              (Riverpod 狀態管理層)
│   ├── anime_database_provider.dart
│   ├── anime_list_provider.dart
│   ├── api_provider.dart
│   ├── connectivity_provider.dart
│   ├── favorite_provider.dart
│   ├── hitokoto_provider.dart
│   ├── router_provider.dart
│   ├── theme_provider.dart
│   └── year_month_provider.dart
├── services/               (業務邏輯與外部 IO 層)
│   ├── anime_database_service.dart
│   ├── api_service.dart
│   ├── dio_client.dart
│   ├── preferences_service.dart
│   └── update_checker.dart
├── screens/                (頁面層)
│   ├── anime/
│   │   ├── anime_detail_screen.dart  ← 動漫詳細資訊完整頁面（含 YT PV 播放）
│   │   ├── anime_list_screen.dart
│   │   └── anime_main_screen.dart
│   ├── favorite/
│   │   └── favorite_main_screen.dart
│   ├── setting/
│   │   └── setting_main_screen.dart
│   ├── error_screen.dart
│   └── no_network_screen.dart
├── utils/
│   ├── date_helper.dart    (119 行)
│   ├── image_save_utils.dart         ← 封面圖儲存/分享工具函數
│   └── logger.dart
└── widgets/                (可複用 UI 元件層)
    ├── anime/
    │   ├── anime_bottom_bar.dart
    │   ├── anime_card.dart
    │   ├── anime_list.dart
    │   ├── anime_sentence.dart
    │   └── year_list_card.dart
    ├── favorite/
    │   └── refresh_btn.dart
    ├── setting/
    │   (已清空，theme_switch 整合至 SettingMainScreen)
    ├── app_loading_indicator.dart
    ├── connectivity_watcher.dart
    ├── my_drawer.dart
    ├── my_scaffold_wrapper.dart
    └── toast_utils.dart
```

分層清晰，各層職責明確：Model → Service → Provider → Widget/Screen。

---

## 2. 架構模式評估

### 2.1 整體架構：MVVM + Riverpod

```
View Layer (Screens/Widgets)
    ↕ ref.watch / ref.read
ViewModel Layer (Providers)
    ↕ dependency injection via Provider
Service Layer (Services)
    ↕ data access
Model Layer (Models)
```

| 層次 | 評分 | 說明 |
|------|------|------|
| Model 層 | EXCELLENT | 純資料類別，包含 `copyWith`、`toMap`、`fromMap` |
| Service 層 | GOOD | 職責分明，已移除 Singleton 反模式 |
| Provider 層 | GOOD | 正確使用 `AsyncNotifier`、`FutureProvider`、`Provider` |
| Screen 層 | GOOD | 各頁面職責清晰，搭配 `MyScaffoldWrapper` 統一佈局 |
| Widget 層 | GOOD | 可複用性高，已按功能分子目錄 |

### 2.2 依賴方向（無循環相依）

```
Models (leaf - 無任何 app 內部依賴)
  ↑
Utils (依賴 Models)
  ↑
Services (依賴 Models)
  ↑
Providers (依賴 Services + Models + Utils)
  ↑
Screens/Widgets (依賴 Providers + Models + Widgets)
```

### 2.3 路由管理

- 使用 `GoRouter`，透過 `routerProvider` 注入，可測試性良好
- `redirect` 負責**啟動時**一次性網路檢查；`ConnectivityWatcher` 負責**運行時**監聽
- 兩套機制刻意並存，請勿刪除其中一套（見 `router_provider.dart` 的 NOTE 說明）

---

## 3. 開放問題

### 3.1 LOW - TODO 註解待決策

**`services/update_checker.dart`**

```dart
// TODO: Google Play 正式上架後，將 showUpdateDialog 的連結改為下方 Play Store 連結
// static const String _playStoreUrl = '...';
```

**建議：** 決定是否上架 Play Store；若確定不上架則直接刪除此 TODO。

---

### 3.2 LOW - `AnimeBottomBar` 特別篇月份無法瀏覽

**`widgets/anime/anime_bottom_bar.dart`**

底部列固定只顯示季番月份（01、04、07、10），已改用 Flutter 原生 `NavigationBar`。
若 API 回傳非季番月份（如特別篇 06），使用者無法透過底部列瀏覽，靜默顯示空列表。

**建議：** 加入使用者提示，或在路由層面限制可進入的月份。

---

### 3.3 LOW - `ConnectivityWatcher` 可能堆疊多個 Dialog

**`widgets/connectivity_watcher.dart`**

透過全域 `navigatorKey` 存取 context 是跳脫 Flutter Widget 樹的操作，在 Dialog 已顯示時重複觸發可能造成多個 Dialog 堆疊。

**建議：** 在導航前檢查當前路由，確保不重複推入相同頁面。

---

### 3.4 LOW - 無障礙標記缺失

| 問題 | 位置 |
|------|------|
| 圖片無 `semanticLabel` | `anime_card.dart`、`anime_detail_screen.dart` 的 `CachedNetworkImage` |
| 愛心按鈕無 `Semantics` 包裝 | `anime_card.dart` 的 `_FavoriteOverlayButton` |
| Tab 文字（日、一...）無輔助說明 | `anime_list_screen.dart` |

**建議：** 若有無障礙需求，為互動元件添加 `Semantics` Widget。

---

## 4. 相依性管理

### 4.1 直接依賴 - 全部最新

所有直接依賴均為最新版本。

### 4.2 間接依賴 - 已升級（2026-03-26）

執行 `flutter pub upgrade` 後，已升級 12 個 patch/minor 版本。

**Major 版本差異（受依賴約束，未升級）：**

| 套件 | 目前版本 | 最新版本 | 說明 |
|------|---------|---------|------|
| `win32` | 5.15.0 | 6.0.0 | Major 版本，升級前需確認 Windows 平台影響 |
| `win32_registry` | 2.1.0 | 3.0.2 | Major 版本，同上 |
| `meta` | 1.17.0 | 1.18.2 | 受 Flutter SDK 版本約束，無法升級 |

### 4.3 依賴審計（2026-04-15 更新）

本次移除 `convex_bottom_bar 3.2.0`（底部導覽列改為 Flutter 原生 `NavigationBar`）。
確認 `dynamic_tabbar` 在本次更新前即已不存在於 pubspec.yaml（上版本已替換為 `contained_tab_bar_view`）。
移除 `toggle_switch` 第三方套件（主題切換改為原生 `SwitchListTile`）。
新增 `youtube_player_flutter ^9.1.3`（動漫詳細頁 YT PV 播放功能）。
移除 `material_symbols_icons ^4.2906.0`（底部列與 Bug 回報圖示改用 Flutter 內建 `Icons`，解決舊版 Android 裝置 icon 無法顯示的問題）。
所有宣告的直接依賴均有實際使用，無需清理。

---

## 5. UI 元件設計

### 5.1 Widget 類型選擇

| 元件 | 類型 | 評估 |
|------|------|------|
| `AnimeMainScreen` | `StatelessWidget` | CORRECT |
| `AnimeListScreen` | `ConsumerStatefulWidget` | CORRECT - 需要 tab index 及快取 |
| `AnimeCard` | `ConsumerStatefulWidget` | CORRECT - 需讀取 Provider |
| `AnimeDetailScreen` | `ConsumerStatefulWidget` | CORRECT - 需要分享載入狀態、YT 控制器生命週期 |
| `FavoriteMainScreen` | `ConsumerStatefulWidget` | CORRECT - 需要搜尋 controller |
| `SettingMainScreen` | `ConsumerStatefulWidget` | CORRECT - 需要 PackageInfo 非同步載入 |
| `AnimeSentence` | `ConsumerStatefulWidget` | CORRECT - 需要 Timer 管理 |
| `YearListCard` | `StatelessWidget` | CORRECT - 純 UI 渲染 |
| `AnimeList` | `StatelessWidget` | CORRECT - 純 ListView 包裝 |
| `AnimeBottomBar` | `ConsumerStatefulWidget` | CORRECT - 需要底部選擇狀態 |
| ~~`ThemeSwitch`~~ | _(已移除)_ | 功能整合至 `SettingMainScreen` 的 `SwitchListTile` |
| `AppLoadingIndicator` | `StatelessWidget` | CORRECT - 純 UI |
| `ConnectivityWatcher` | `ConsumerStatefulWidget` | CORRECT - 需要監聽 Stream |

無多餘的 StatefulWidget，所有 Widget 類型選擇均合理。

### 5.2 Material 3 合規性（2026-04-03 全面達成）

全專案已完成 Material 3 遷移，無任何遺留的舊版模式：

| 修正項目 | 原始問題 | 修正內容 |
|----------|----------|----------|
| `error_screen.dart` | `Colors.redAccent`、`Colors.red` 硬編碼 | 改用 `colorScheme.errorContainer`、`colorScheme.error` |
| `favorite_main_screen.dart` | `Colors.lightBlue` 硬編碼 | 改用 `colorScheme.primary` |
| `anime_card.dart` | `Colors.redAccent` 硬編碼 | 改用 `colorScheme.error` |
| `anime_detail_screen.dart` | `Colors.redAccent`、`Colors.grey`、`fontSize: 11` 硬編碼 | 改用 ColorScheme token + `textTheme.labelSmall` |
| `anime_list_screen.dart` | `Colors.red` 硬編碼 | 改用 `colorScheme.error` |
| `setting_main_screen.dart` | 舊版 `ListView + Divider` 佈局 | 重新設計為 Card 分區塊的簡約 M3 風格 |
| `widgets/setting/theme_switch.dart` | 獨立 Widget，邏輯分散 | 刪除，整合至 `SettingMainScreen` 的 `SwitchListTile` |

### 5.3 效能設計（已優化）

- **`Theme.of(context)`**：使用 `InheritedWidget`，查詢已被 Flutter 優化為 O(1)，正確寫法。
- **`AnimeListScreen` 快取**：`build()` 只負責 Guard 判斷，`_rebuildCache()` 集中快取計算，`didUpdateWidget` 負責年份切換清除，`build()` 無副作用。
- **`favoritedNamesProvider`**：集中 Set 查詢，消除 N+1 DB 問題，所有 `AnimeCard` 共享同一份收藏快取。

---

## 6. 未來建議

### 6.1 動漫詳細頁重構（已完成 - 2026-04-14）

原 `anime_detail_modal.dart` 彈窗已重構為完整頁面，並完成以下拆分：

- `screens/anime/anime_detail_screen.dart`：動漫詳細資訊完整頁面，內含 YT PV 播放器（`youtube_player_flutter`）、封面圖、資訊 Chip、分享等功能
- `utils/image_save_utils.dart`：封面圖儲存/分享工具函數獨立提取

改為完整頁面（非 Dialog）的主要原因：`YoutubePlayerBuilder` 的全螢幕切換需要推入新路由，在 Dialog 內會有 overflow 問題。

### 6.2 `FavoriteSearchBar` 獨立 Widget（優先級：LOW）

`favorite_main_screen.dart` 可進一步提取 `FavoriteSearchBar` 為獨立 Widget，封裝 `TextEditingController` lifecycle，提升元件可複用性。

### 6.3 `win32` Major 版本升級評估（優先級：LOW）

`win32 6.0.0` 和 `win32_registry 3.0.2` 有 major 版本更新，目前受依賴約束未升級。建議在下次 Flutter SDK 升級時一併評估。

---

## 7. 測試覆蓋率

### 7.1 現況：極低（估計 < 5%）

```
test/
└── widget_test.dart    # 僅有基本煙霧測試
```

### 7.2 建議測試清單（依優先序）

**Priority 1 - 業務邏輯單元測試（最高效益）**

```dart
// test/utils/date_helper_test.dart
void main() {
  group('DateHelper.parseAnimeDate', () {
    test('解析 MM/DD 格式（含年份）');
    test('解析 YYYY/MM/DD 格式');
    test('解析失敗回傳 null');
    test('無效月份（13）應回傳 null');
    test('無效日期（32）應回傳 null');
  });

  group('DateHelper.filterByWeekday', () {
    test('過濾出正確星期的動漫');
    test('空列表回傳空列表');
  });

  group('DateHelper.filterOther', () {
    test('date 為空字串的項目應被納入');
    test('date 無法解析的項目應被納入');
    test('date 可正常解析的項目不應被納入');
  });

  group('DateHelper.compareAnimeByDateTime', () {
    test('ascending 排序');
    test('descending 排序');
    test('無法解析日期的項目排到最後');
  });
}
```

**Priority 2 - Service 層測試**

```dart
// test/services/anime_database_service_test.dart
void main() {
  late AnimeDatabaseService sut;

  setUp(() => sut = AnimeDatabaseService());

  test('insertAnimeItem 成功回傳 rowId > 0');
  test('insertAnimeItem 重複插入使用 ConflictAlgorithm.ignore');
  test('deleteAnimeItemByName 刪除存在的項目');
  test('searchAnimeItemsByName 模糊搜尋');
  test('getAllAnimeItems 回傳空列表當無資料');
}
```

**Priority 3 - Provider 狀態測試**

```dart
// test/providers/favorite_provider_test.dart
void main() {
  test('favoritedNamesProvider 在 loading 狀態回傳空 Set');
  test('favoritedNamesProvider 在 data 狀態回傳正確名稱 Set');
  test('favoritedNamesProvider 在 error 狀態回傳空 Set');
}
```

---

## 8. 總評

| 面向 | 評分 | 說明 |
|------|------|------|
| **架構分層** | 9/10 | MVVM + Riverpod 實作正確，依賴方向乾淨 |
| **模組職責** | 8/10 | 各層職責清晰；`anime_detail_modal.dart` 可繼續拆分 |
| **代碼品質** | 9/10 | 巢狀、build 方法長度、魔法數字問題均已修復 |
| **Bug 風險** | 9/10 | 已知問題均已修復；剩餘為 LOW 級別設計取捨 |
| **相依性管理** | 10/10 | 直接 + 間接依賴全部升至最新可用版本，移除 convex_bottom_bar，無未使用套件 |
| **UI 元件設計** | 10/10 | Widget 類型選擇正確，效能優化到位；全面完成 Material 3 遷移，無硬編碼顏色 |
| **測試覆蓋率** | 2/10 | 幾乎無測試，是目前最大的技術債 |
| **整體評分** | **8.3/10** | 架構健康，代碼品質良好，Material 3 全面達成；主要技術債在測試 |

### 最高投資報酬率的改進

1. **建立 `DateHelper` 單元測試** — 核心業務邏輯，補測試成本低、效益高
2. ~~**拆分 `anime_detail_modal.dart`**~~ — 已於 2026-04-14 完成，重構為 `AnimeDetailScreen` 完整頁面
3. **處理 `ConnectivityWatcher` Dialog 堆疊問題** — 邊緣情境的穩定性修復

---

*報告由 Claude Code 自動分析生成。所有行號以分析時版本為準，可能隨代碼更新而變動。*
