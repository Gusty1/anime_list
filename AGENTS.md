# AGENTS.md — Anime List Flutter App

> Operational guide for AI agents. Describes the project architecture, conventions, forbidden operations, and correct workflows for common tasks.
> Written 2026-04-28, based on version 1.3.1+15.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Key Dependencies](#2-tech-stack--key-dependencies)
3. [Directory Structure](#3-directory-structure)
4. [Architecture Conventions](#4-architecture-conventions)
5. [Critical Design Decisions (Do Not Change)](#5-critical-design-decisions-do-not-change)
6. [Common Task Workflows](#6-common-task-workflows)
7. [Known Technical Debt & Open Issues](#7-known-technical-debt--open-issues)
8. [Test Coverage Status](#8-test-coverage-status)

---

## 1. Project Overview

**Purpose:** Taiwan seasonal anime browser app. Data sourced from ACG Taiwan Anime List.
**Platforms:** Android (primary), Windows (secondary).
**Language:** Dart / Flutter, Material 3 design system, portrait-only orientation enforced.
**Architecture:** MVVM + Riverpod 3 (`flutter_riverpod ^3.2.1`).

---

## 2. Tech Stack & Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod ^3.2.1` | State management (AsyncNotifier / Provider) |
| `go_router ^17.1.0` | Declarative routing |
| `flex_color_scheme ^8.4.0` | Material 3 theming (aquaBlue scheme) |
| `dio ^5.9.1` | HTTP client |
| `sqflite ^2.4.2` | Local SQLite favorites database (v2 schema) |
| `youtube_player_flutter ^9.1.3` | PV playback (requires `YoutubePlayerBuilder` wrapping Scaffold) |
| `cached_network_image ^3.4.1` | Cover image caching |
| `feedback ^3.2.0` | Screenshot feedback (ZhTwFeedbackLocalizations) |
| `connectivity_plus ^7.0.0` | Network status (returns `List<ConnectivityResult>`) |
| `share_plus ^13.0.0` | Share anime info (ShareParams API) |
| `easy_image_viewer ^1.5.1` | Fullscreen cover image viewer |
| `url_launcher ^6.3.2` | Open official site / MAL links |
| `permission_handler ^12.0.1` | Android storage permissions |
| `image_gallery_saver_plus ^4.0.1` | Save cover image to gallery |

---

## 3. Directory Structure

```
lib/
├── constants.dart          Global constants (API URL, route names, string constants)
├── main.dart               App entry point, ProviderScope, navigatorKey declaration
├── generated/assets.dart   Auto-generated asset paths (do not edit manually)
├── l10n/                   Feedback localization (ZhTwFeedbackLocalizations)
├── models/
│   ├── anime_item.dart     Anime data model (fromJson / fromMap / copyWith / == / hashCode)
│   └── hitokoto.dart       Hitokoto quote data model
├── providers/              Riverpod state management layer
│   ├── anime_database_provider.dart   SQLite service provider (keepAlive: true)
│   ├── anime_list_provider.dart       Fetch anime list by year/month
│   ├── api_provider.dart              DioClient / ApiService providers
│   ├── connectivity_provider.dart     Network status Stream provider
│   ├── favorite_provider.dart         Favorites list + favoritedNamesProvider (N+1 prevention)
│   ├── hitokoto_provider.dart         Hitokoto quote API
│   ├── router_provider.dart           GoRouter instance
│   ├── theme_provider.dart            Dark/light mode toggle
│   └── year_month_provider.dart       Currently selected year.month string
├── services/
│   ├── anime_database_service.dart    SQLite CRUD (v2 schema)
│   ├── api_service.dart               Remote API fetch (Hitokoto / AnimeItem)
│   ├── dio_client.dart                Dio instance setup (timeout = 10s)
│   ├── preferences_service.dart       SharedPreferences wrapper
│   └── update_checker.dart            GitHub Releases update check
├── screens/
│   ├── anime/
│   │   ├── anime_detail_screen.dart   Anime detail (full-page, with YT PV + cover + Chips)
│   │   ├── anime_list_screen.dart     Seasonal anime list (tabbed by weekday)
│   │   └── anime_main_screen.dart     Home screen (year selector + quote)
│   ├── favorite/
│   │   └── favorite_main_screen.dart  Favorites list (search + SQLite)
│   ├── setting/
│   │   └── setting_main_screen.dart   Settings (dark mode, app version, feedback)
│   ├── error_screen.dart              GoRouter errorBuilder page
│   └── no_network_screen.dart         No-network fallback page
├── utils/
│   ├── date_helper.dart               Date parsing/sorting/filtering utilities (core business logic)
│   ├── image_save_utils.dart          Cover image save/share utilities (handleImageLongPress)
│   └── logger.dart                    Global appLogger (Logger package)
└── widgets/
    ├── anime/
    │   ├── anime_bottom_bar.dart      Bottom seasonal month navigation (NavigationBar, 01/04/07/10 only)
    │   ├── anime_card.dart            Anime card (tap to open detail)
    │   ├── anime_list.dart            ListView wrapper
    │   ├── anime_sentence.dart        Hitokoto quote widget (Timer-based rotation)
    │   └── year_list_card.dart        Year selection card
    ├── favorite/
    │   └── refresh_btn.dart           Favorites page reload FAB
    ├── app_loading_indicator.dart     Loading animation (flutter_spinkit)
    ├── connectivity_watcher.dart      Network disconnect listener (global navigatorKey)
    ├── my_drawer.dart                 Side drawer menu
    ├── my_scaffold_wrapper.dart       Unified Scaffold (AppBar + Drawer + bottom bar)
    └── toast_utils.dart               Toast utility (fluttertoast)
```

---

## 4. Architecture Conventions

### 4.1 Dependency Direction (Strict)

```
Models (leaf — no internal app dependencies)
  ↑
Utils (depends on Models)
  ↑
Services (depends on Models)
  ↑
Providers (depends on Services + Models + Utils)
  ↑
Screens / Widgets (depends on Providers + Models)
```

**Forbidden:** Service depending on Provider; Widget calling Service directly; Model depending on Provider.

### 4.2 Riverpod Usage Rules

- **AsyncNotifier** — for async state with side effects (favorites list, anime list)
- **FutureProvider** — for read-only async data (hitokoto, update check)
- **Provider** — for derived synchronous state (`favoritedNamesProvider`, `routerProvider`)
- Use `ref.invalidate(favoriteProvider)` to trigger favorites reload; do not mutate state directly
- `animeDatabaseServiceProvider` is marked `keepAlive: true` to maintain the SQLite connection throughout the app lifecycle

### 4.3 SQLite Schema (v2)

Table: `anime_items`, columns: `name (PK), date, time, carrier, season, originalName, img, description, official, pv (nullable)`.
When adding a new column, always update both `_onCreate` (fresh installs) and `_onUpgrade` (migration), and increment `_dbVersion`.

### 4.4 Material 3 Theming Rules

- **Forbidden:** hardcoded colors such as `Colors.red`, `Colors.grey`
- Always use `colorScheme.*` (e.g., `colorScheme.error`, `colorScheme.primary`)
- Always use `textTheme.*` for font sizes (e.g., `textTheme.labelSmall`)

### 4.5 Network Status Handling

`connectivity_plus 7.x` `checkConnectivity()` returns **`List<ConnectivityResult>`** (not a single value).
To detect no network, use:

```dart
final hasNoNetwork = result.every((r) => r == ConnectivityResult.none);
```

---

## 5. Critical Design Decisions (Do Not Change)

### 5.1 Dual-Layer Network Check

The `redirect` in `router_provider.dart` (runs once at startup) and `connectivity_watcher.dart` (runtime Stream listener) **intentionally coexist**. Each serves a distinct role — do not remove either.

### 5.2 YoutubePlayerBuilder Must Wrap Scaffold

In `anime_detail_screen.dart`, when a PV is present, `YoutubePlayerBuilder` must be the outermost widget wrapping the entire `Scaffold`. This is a technical requirement of `youtube_player_flutter` for fullscreen toggle — do not move the player inside the Scaffold body.

### 5.3 navigatorKey Declared in main.dart

`navigatorKey` is declared in `main.dart` and shared by both `router_provider.dart` (GoRouter) and `connectivity_watcher.dart` (dialog navigation). Do not move it to another file unless both import sites are updated simultaneously.

### 5.4 favoritedNamesProvider Prevents N+1

`favoritedNamesProvider` caches favorited names as a `Set<String>`, shared across all `AnimeCard` instances to avoid per-card DB queries. Do not query the DB directly in Widget/Screen layer to check favorite status.

### 5.5 AnimeBottomBar Shows Seasonal Months Only

The bottom navigation bar is fixed to display months 01, 04, 07, and 10 only. This is a deliberate design decision, not a bug. Supporting non-seasonal months (e.g., specials in month 06) requires a separate design review.

---

## 6. Common Task Workflows

### Add a New Anime Data Field

1. `models/anime_item.dart` — add field, update `fromJson`, `fromMap`, `toJson`, `toMap`, `copyWith`, `==`, `hashCode`
2. `services/anime_database_service.dart` — add column constant, update `_onCreate`, add `_onUpgrade` case, increment `_dbVersion`

### Add a New Route / Screen

1. `constants.dart` — add route path constant
2. `providers/router_provider.dart` — add `GoRoute`
3. Create the corresponding Screen widget

### Change Theme Color

Modify only `FlexScheme.aquaBlue` in `main.dart`. Never hardcode colors inside individual widgets.

### Update PV Playback Logic

All changes must be made inside `_AnimeDetailScreenState` in `anime_detail_screen.dart`. Key rules:
- `YoutubePlayerController` is created in `initState` and disposed in `dispose`
- `_restoreSystemUI()` must be called in four places: `dispose`, `onExitFullScreen`, back button handler, and `AppLifecycleState.resumed`

### Add a New SQLite Operation

Add the method to `AnimeDatabaseService`, then inject it via `animeDatabaseServiceProvider` into the Provider layer. Never instantiate `AnimeDatabaseService()` directly in Widget or Screen code.

---

## 7. Known Technical Debt & Open Issues

| Priority | Description |
|----------|-------------|
| LOW | `update_checker.dart` contains a Play Store TODO pending a decision |
| LOW | `ConnectivityWatcher` may stack multiple dialogs on rapid disconnect/reconnect cycles |
| LOW | `AnimeBottomBar` cannot navigate to non-seasonal months (e.g., specials in month 06) |
| LOW | Multiple `CachedNetworkImage` usages are missing `semanticLabel` (accessibility) |
| LOW | Search bar in `FavoriteMainScreen` could be extracted into a standalone `FavoriteSearchBar` widget |
| LOW | `win32 ^6.0.0` / `win32_registry ^3.0.2` major version upgrades pending |

---

## 8. Test Coverage Status

Current test coverage is very low (< 5%). Only a basic smoke test exists in `test/widget_test.dart`.

**Priority test targets:**

1. `utils/date_helper.dart` — `parseAnimeDate`, `filterByWeekday`, `filterOther`, `compareAnimeByDateTime`
2. `services/anime_database_service.dart` — CRUD operations, LIKE search, schema migration
3. `providers/favorite_provider.dart` — loading / data / error states

Run tests:
```bash
flutter test
```
