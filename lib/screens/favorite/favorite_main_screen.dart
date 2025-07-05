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

  int _totalAnimeCount = 0;

  @override
  void initState() {
    super.initState();
    _queryMyAnimeList(context);
  }

  @override
  void dispose() {
    // 在 Widget (State) 被銷毀時，必須釋放 TextEditingController，避免內存洩漏
    _textController.dispose();
    super.dispose();
  }

  // 處理按鈕點擊事件的方法
  Future<void> _queryMyAnimeList(BuildContext context) async {
    try {
      if (_loading || !mounted) return;
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
          final timePartsA = a.time.split(':');
          final hourA = int.parse(timePartsA[0]);
          final minuteA = int.parse(timePartsA[1]);
          final dateTimeA = DateTime(yearIntA, monthA, dayA, hourA, minuteA);

          // 解析項目 b 的日期和時間
          final datePartsB = b.date.split('/');
          final yearIntB = int.parse(datePartsB[0]);
          final monthB = int.parse(datePartsB[1]);
          final dayB = int.parse(datePartsB[2]);
          final timePartsB = b.time.split(':');
          final hourB = int.parse(timePartsB[0]);
          final minuteB = int.parse(timePartsB[1]);
          final dateTimeB = DateTime(yearIntB, monthB, dayB, hourB, minuteB);

          return dateTimeB.compareTo(dateTimeA);
        } catch (e) {
          appLogger.e('錯誤: Sort - 處理日期/時間 "${a.name}" 失敗 - ${e.toString()}');
          return 0; // 返回 0 表示相等，不改變相對順序
        }
      });

      setState(() {
        _animeList = result;
        _loading = false;
      });

      if(_textController.text.isEmpty){
        setState(() {
          _totalAnimeCount = _animeList.length;
        });
      }
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
        _queryMyAnimeList(context);
      }
    });
    String emptyText = '';
    if (_animeList.isEmpty && _textController.text.isNotEmpty) {
      emptyText = '找不到符合條件的動漫';
    } else if (_animeList.isEmpty) {
      emptyText = '尚未收藏任何動漫';
    }

    return Container(
      padding: const EdgeInsets.all(5.0),
      margin: const EdgeInsets.all(5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              // 設定邊框
              border: Border.all(color: Theme.of(context).colorScheme.surfaceTint, width: 2.0),
              // 設定圓角
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).colorScheme.surface,
            ),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: !_loading ,
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: '請輸入動漫名稱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text, // 設置彈出的鍵盤類型 (text, number, emailAddress 等)
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: IconButton(
                    onPressed:
                        !_loading
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
                        return Theme.of(context).colorScheme.secondaryContainer;
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
                      text: '$_totalAnimeCount',
                      style: const TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' 部動漫'),
                  ],
                ),
                // Text.rich 的 style 屬性設定了整個 TextSpan 樹的基礎樣式
                // 子 TextSpan 的 style 會覆蓋這裡的設定
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          if (_loading)
            Expanded(child: const AppLoadingIndicator())
          else if (_animeList.isEmpty) // 如果載入完成但列表為空
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
                      emptyText,
                      textAlign: TextAlign.center,
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
