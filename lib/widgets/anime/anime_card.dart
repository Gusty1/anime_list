import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/providers/year_month_provider.dart';
import 'package:anime_list/providers/anime_database_provider.dart';
import 'package:anime_list/providers/favorite_provider.dart';
import 'package:anime_list/models/anime_item.dart';
import 'package:anime_list/widgets/app_loading_indicator.dart';
import 'package:anime_list/widgets/anime/anime_detail_modal.dart';
import 'package:anime_list/widgets/toast_utils.dart';

/// 封面圖寬度
const double _coverWidth = 130.0;

/// 封面圖高度
const double _coverHeight = 180.0;

/// 動畫卡片元件
///
/// 顯示單一動畫項目的資訊（封面圖、名稱、播出時間等），
/// 點擊後開啟詳細資訊彈窗。
class AnimeCard extends ConsumerStatefulWidget {
  final AnimeItem animeItem;

  /// 是否為收藏頁視圖。
  ///
  /// `true` 時日期已包含年份（YYYY/MM/DD），不顯示「首播時間」前綴；
  /// `false`（預設）時為列表頁格式（MM/DD），加上前綴以提示語境。
  final bool isFavoriteView;

  const AnimeCard({
    super.key,
    required this.animeItem,
    this.isFavoriteView = false,
  });

  @override
  ConsumerState<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends ConsumerState<AnimeCard> {
  /// 切換收藏狀態（新增或取消收藏）
  ///
  /// 收藏狀態由 [favoritedNamesProvider] 統一管理，
  /// 操作完成後透過 [ref.invalidate] 通知所有相依 Widget 重建，
  /// 不再維護本地 _favorite 欄位，消除 N+1 DB 查詢問題。
  Future<void> _toggleFavorite() async {
    if (!mounted) return;

    final isFavorite = ref.read(favoritedNamesProvider).contains(
      widget.animeItem.name,
    );
    final currentYearMonth = ref.read(yearMonthProvider);
    final dbService = ref.read(animeDatabaseServiceProvider);
    int result = 0;

    if (isFavorite) {
      // 目前已收藏 → 取消收藏
      result = await dbService.deleteAnimeItemByName(widget.animeItem.name);
    } else {
      // 目前未收藏 → 新增收藏（加上年份前綴以利排序）
      final year = currentYearMonth.split('.')[0];
      final newItem = widget.animeItem.copyWith(
        date: '$year/${widget.animeItem.date}',
      );
      result = await dbService.insertAnimeItem(newItem);
    }

    // result > 0：操作成功；result == 0 && !isFavorite：資料已存在（ConflictAlgorithm.ignore）
    // 兩種情況都需要重新同步 Provider，僅操作成功時才顯示提示
    final shouldRefresh = result > 0 || (result == 0 && !isFavorite);
    if (shouldRefresh) {
      // 通知收藏列表 Provider 重新載入，favoritedNamesProvider 會自動跟著更新
      ref.invalidate(favoriteProvider);
      if (result > 0) {
        if (!mounted) return;
        ToastUtils.showShortToast(context, isFavorite ? '取消收藏成功' : '收藏成功');
      }
    } else {
      if (!mounted) return;
      ToastUtils.showShortToastError(context, '發生錯誤');
    }
  }

  /// 組合日期顯示文字
  ///
  /// 列表頁（[isFavoriteView] == false）加「首播時間」前綴；
  /// 收藏頁（[isFavoriteView] == true）直接顯示完整日期，語境已明確。
  String get _dateDisplayText {
    final date = widget.animeItem.date;
    final time = widget.animeItem.time;
    final prefix = widget.isFavoriteView ? '' : '首播時間: ';
    return '$prefix$date $time';
  }

  @override
  Widget build(BuildContext context) {
    // 從 Provider 讀取收藏狀態，避免個別 DB 查詢
    final isFavorite = ref.watch(favoritedNamesProvider).contains(
      widget.animeItem.name,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AnimeDetailModal(
                animeItem: widget.animeItem,
                toggleFavorite: _toggleFavorite,
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 左側封面圖（含收藏愛心 overlay）──
              SizedBox(
                width: _coverWidth,
                height: _coverHeight,
                child: Stack(
                  children: [
                    // 封面圖
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: CachedNetworkImage(
                          imageUrl: widget.animeItem.fullImageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const AppLoadingIndicator(),
                          errorWidget:
                              (context, url, error) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 36.0,
                                ),
                              ),
                        ),
                      ),
                    ),

                    // 收藏愛心按鈕（右上角 overlay）
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _FavoriteOverlayButton(
                        isFavorite: isFavorite,
                        onTap: _toggleFavorite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),

              // ── 右側文字資訊 ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 動畫名稱
                    Text(
                      widget.animeItem.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),

                    // 原作名
                    Text(
                      widget.animeItem.originalName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6.0),

                    // 播出資訊
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _dateDisplayText,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        Icon(
                          Icons.tv,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.animeItem.displayCarrier} / ${widget.animeItem.season}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),

                    // 簡介
                    Text(
                      widget.animeItem.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 封面圖右上角收藏愛心按鈕
///
/// 封裝半透明圓形背景與愛心圖示，將愛心 overlay 邏輯從 [AnimeCard]
/// 的巢狀結構中獨立出來，降低 [AnimeCard.build] 的巢狀深度。
class _FavoriteOverlayButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteOverlayButton({
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.redAccent : colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}
