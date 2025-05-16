import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/favorite_refresh_provider.dart';
import '../../services/anime_database_service.dart';
import '../../models/anime_item.dart';
import '../../widgets/anime/anime_list.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/toast_utils.dart';
import '../../utils/logger.dart';

class FavoriteMainScreen extends ConsumerStatefulWidget {
  const FavoriteMainScreen({super.key});

  @override
  ConsumerState<FavoriteMainScreen> createState() => _FavoriteMainScreenState();
}

class _FavoriteMainScreenState extends ConsumerState<FavoriteMainScreen> {
  final TextEditingController _textController = TextEditingController();
  final dbService = AnimeDatabaseService();
  bool _loading = false;
  List<AnimeItem> _animeList = [];



  @override
  void initState() {
    super.initState();
    _queryMyAnimeList(context);
  }

  @override
  void dispose() {
    // 2. 在 Widget (State) 被銷毀時，必須釋放 TextEditingController
    // 這樣可以避免內存洩漏
    _textController.dispose();
    super.dispose();
  }

  // 處理按鈕點擊事件的方法
  Future<void> _queryMyAnimeList(context) async {
    try {
      setState(() {
        _loading = true;
      });
      final inputText = _textController.text;
      List<AnimeItem> result = [];
      if (inputText.trim().isEmpty) {
        result = await dbService.getAllAnimeItems();
      } else {
        result = await dbService.searchAnimeItemsByName(inputText);
      }
      result.sort((a, b) {
        try {
          // 解析項目 a 的日期和時間
          final datePartsA = a.date.split('/');
          final yearIntA = int.parse(datePartsA[0]);
          final monthA = int.parse(datePartsA[1]);
          final dayA = int.parse(datePartsA[2]);
          final dateTimeA = DateTime(yearIntA, monthA, dayA);

          // 解析項目 b 的日期和時間
          final datePartsB = b.date.split('/');
          final yearIntB = int.parse(datePartsB[0]);
          final monthB = int.parse(datePartsB[1]);
          final dayB = int.parse(datePartsB[2]);
          final dateTimeB = DateTime(yearIntB, monthB, dayB);

          return dateTimeB.compareTo(dateTimeA);
        } catch (e) {
          appLogger.e(
            '錯誤: Sort - 處理日期/時間 "${a.date}" "${a.time}" 或 "${b.date}" "${b.time}" 失敗 (排序時) - ${e.toString()}',
          );
          return 0; // 返回 0 表示相等，不改變相對順序
        }
      });

      setState(() {
        _animeList = result;
        _loading = false;
      });
    } catch (e) {
      appLogger.e('查詢失敗: $e');
      ToastUtils.showShortToastError(context, '查詢失敗');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(favoriteRefreshProvider, (previous, next) {
      // 判斷布林值是否確實發生了變化
      if (previous != next) {
        appLogger.i('偵測到 favoriteRefreshProvider 狀態改變 ($previous -> $next)，觸發 _queryMyAnimeList 方法');
        // 檢查 Widget 是否仍然掛載，避免在 disposed 後呼叫 _queryMyAnimeList
        if (mounted) {
          appLogger.i('Widget 已掛載，呼叫 _queryMyAnimeList 方法');
          // *** 在這裡呼叫您本地的 _queryMyAnimeList 方法 ***
          _queryMyAnimeList(context);
        } else {
          appLogger.w('Widget 已被 disposed，Provider 狀態改變但未觸發 _queryMyAnimeList');
        }
      }
    });

    return Container(
      padding: const EdgeInsets.all(5.0),
      margin: const EdgeInsets.all(5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // 內容靠頂部對齊
        crossAxisAlignment: CrossAxisAlignment.stretch, // 子 Widget 沿水平方向拉伸
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              // 設定邊框
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceTint,
                width: 2.0, // 邊框粗細
              ),
              // 設定圓角
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).colorScheme.surface,
            ),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: !_loading && _animeList.isNotEmpty,
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: '輸入動漫名稱',
                      border: OutlineInputBorder() ,
                    ),
                    keyboardType: TextInputType.text, // 設置彈出的鍵盤類型 (text, number, emailAddress 等)
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: IconButton(
                    onPressed:
                        !_loading && _animeList.isNotEmpty
                            ? () => _queryMyAnimeList(context)
                            : null,
                    icon: Icon(Icons.search),
                    color: Theme.of(context).colorScheme.primary,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        // 根據按鈕狀態設置背景色
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.grey; // 禁用時使用灰色
                        }
                        return Theme.of(context).colorScheme.secondaryContainer; // 正常時使用次要容器色
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return Theme.of(context).colorScheme.onSurface; // 禁用時使用表面色對比色
                        }
                        return Theme.of(context).colorScheme.onSecondaryContainer; // 正常時使用次要容器色對比色
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_animeList.isNotEmpty)
            Center(
              child: Text.rich(
                TextSpan(
                  text: '共收藏 ',
                  children: <TextSpan>[
                    TextSpan(
                      text: '${_animeList.length}',
                      style: const TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' 部動漫'),
                  ],
                ),
                // Text.rich 的 style 屬性設定了整個 TextSpan 樹的基礎樣式
                // 子 TextSpan 的 style 會覆蓋這裡的設定
                style: Theme.of(context).textTheme.bodyLarge, // <--- 設定基礎樣式
              ),
            ),
          if (_loading)
            const AppLoadingIndicator()

          else if (_animeList.isEmpty)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_emoticon,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 60,
                  ),
                  Center(
                    child: Text(
                      '尚未收藏任何動漫',
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _queryMyAnimeList(context),
                child: AnimeList(animeList: _animeList),
              ),
            ),
        ],
      ),
    );
  }
}
