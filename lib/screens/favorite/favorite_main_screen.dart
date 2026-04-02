import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/models/anime_item.dart';
import 'package:anime_list/providers/favorite_provider.dart';
import 'package:anime_list/widgets/anime/anime_list.dart';
import 'package:anime_list/widgets/app_loading_indicator.dart';
import 'package:anime_list/widgets/toast_utils.dart';
import 'package:anime_list/utils/logger.dart';

/// 收藏頁面
///
/// 使用 [favoriteProvider] (AsyncNotifierProvider) 管理收藏列表狀態，
/// 支援搜尋、重新載入功能。
class FavoriteMainScreen extends ConsumerStatefulWidget {
  const FavoriteMainScreen({super.key});

  @override
  ConsumerState<FavoriteMainScreen> createState() => _FavoriteMainScreenState();
}

class _FavoriteMainScreenState extends ConsumerState<FavoriteMainScreen> {
  final TextEditingController _textController = TextEditingController();

  // 搜尋狀態
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // 每次進入收藏頁時自動重新載入資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(favoriteProvider);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 執行搜尋查詢
  Future<void> _search() async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final query = _textController.text.trim();
      final notifier = ref.read(favoriteProvider.notifier);
      // 透過 Notifier 的 searchAndUpdate 方法更新 Provider 狀態
      await notifier.searchAndUpdate(query);
    } catch (e) {
      appLogger.e('搜尋失敗: $e');
      if (mounted) {
        ToastUtils.showShortToastError(context, '搜尋失敗');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  /// 搜尋欄 UI
  ///
  /// [hasNoFavorites] 為 true 時表示收藏列表完全為空（非搜尋無結果），
  /// 此時停用輸入框與搜尋按鈕，避免對空資料庫發出無意義的搜尋請求。
  Widget _buildSearchBar({required bool hasNoFavorites}) {
    final isDisabled = _isSearching || hasNoFavorites;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                enabled: !isDisabled,
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: '搜尋收藏的動漫...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  filled: false,
                ),
                keyboardType: TextInputType.text,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: IconButton.filledTonal(
                onPressed: !isDisabled ? _search : null,
                icon: const Icon(Icons.search),
                tooltip: '搜尋',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 空收藏列表的提示狀態 UI
  Widget _buildEmptyState(BuildContext context) {
    final emptyText =
        _textController.text.isNotEmpty ? '找不到符合條件的動漫' : '尚未收藏任何動漫';
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            color: Theme.of(context).colorScheme.secondary,
            size: 60,
          ),
          Center(
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 有資料時的收藏列表 UI（含計數器與下拉重新整理）
  Widget _buildFavoriteList(
    BuildContext context,
    List<AnimeItem> animeList,
  ) {
    return Expanded(
      child: Column(
        children: [
          Center(
            child: Text.rich(
              TextSpan(
                text: '共收藏 ',
                children: <TextSpan>[
                  TextSpan(
                    text: '${animeList.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' 部動漫'),
                ],
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // 清空搜尋欄並重新載入全量資料
                _textController.clear();
                await ref.read(favoriteProvider.notifier).refresh();
              },
              child: AnimeList(
                animeList: animeList,
                isFavoriteView: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteAsync = ref.watch(favoriteProvider);

    // 「真正的空收藏」：資料已載入、列表為空、且搜尋欄也沒有輸入值
    // 若搜尋欄有值而無結果，使用者仍需要能修改搜尋詞，不應 disabled
    final hasNoFavorites =
        favoriteAsync.asData?.value.isEmpty == true &&
        _textController.text.isEmpty;

    return Container(
      padding: const EdgeInsets.all(5.0),
      margin: const EdgeInsets.all(5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSearchBar(hasNoFavorites: hasNoFavorites),

          // 收藏列表（使用 AsyncValue.when 處理狀態）
          favoriteAsync.when(
            loading: () => const Expanded(child: AppLoadingIndicator()),
            error:
                (err, stack) => Expanded(
                  child: Center(
                    child: Text(
                      '載入收藏失敗: $err',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
            data: (animeList) {
              if (animeList.isEmpty) return _buildEmptyState(context);
              return _buildFavoriteList(context, animeList);
            },
          ),
        ],
      ),
    );
  }
}
