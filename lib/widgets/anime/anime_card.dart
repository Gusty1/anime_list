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

/// 動畫卡片元件
///
/// 顯示單一動畫項目的資訊（封面圖、名稱、播出時間等），
/// 點擊後開啟詳細資訊彈窗。
class AnimeCard extends ConsumerStatefulWidget {
  final AnimeItem animeItem;

  const AnimeCard({super.key, required this.animeItem});

  @override
  ConsumerState<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends ConsumerState<AnimeCard> {
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    // 透過 Provider 取得 DB Service，查詢收藏狀態
    final dbService = ref.read(animeDatabaseServiceProvider);
    dbService.getAnimeItemByName(widget.animeItem.name).then((value) {
      if (mounted) {
        setState(() {
          _favorite = value != null;
        });
      }
    });
  }

  /// 切換收藏狀態（新增或取消收藏）
  Future<void> _toggleFavorite() async {
    if (!mounted) return;

    final currentYearMonth = ref.read(yearMonthProvider);
    final dbService = ref.read(animeDatabaseServiceProvider);
    int result = 0;

    if (_favorite) {
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

    if (result > 0) {
      if (!mounted) return;
      ToastUtils.showShortToast(context, _favorite ? '取消收藏成功' : '收藏成功');
      setState(() {
        _favorite = !_favorite;
      });
      // 通知收藏列表 Provider 重新載入
      ref.invalidate(favoriteProvider);
    } else if (result == 0 && !_favorite) {
      // 資料已存在，同步收藏狀態
      setState(() {
        _favorite = true;
      });
    } else {
      if (!mounted) return;
      ToastUtils.showShortToastError(context, '發生錯誤');
    }
  }

  /// 組合日期顯示文字（依格式自動加前綴）
  String get _dateDisplayText {
    final date = widget.animeItem.date;
    final time = widget.animeItem.time;
    // MM/DD（列表頁）→ 加「首播時間」前綴；YYYY/MM/DD（收藏頁）→ 直接顯示
    final prefix = date.split('/').length == 2 ? '首播時間: ' : '';
    return '$prefix$date $time';
  }

  @override
  Widget build(BuildContext context) {
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
                favorite: _favorite,
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
                width: 130,
                height: 180,
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
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.75),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _favorite ? Icons.favorite : Icons.favorite_border,
                            color:
                                _favorite
                                    ? Colors.redAccent
                                    : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
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
