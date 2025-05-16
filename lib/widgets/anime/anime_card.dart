import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/year_month_provider.dart';
import '../../models/anime_item.dart';
import '../../constants.dart';
import '../app_loading_indicator.dart';
import '../../utils/show_carrier.dart';
import './anime_detail_modal.dart';
import '../../services/anime_database_service.dart';
import '../toast_utils.dart';

class AnimeCard extends ConsumerStatefulWidget {
  final AnimeItem animeItem;

  const AnimeCard({super.key, required this.animeItem});

  @override
  ConsumerState<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends ConsumerState<AnimeCard> {
  final dbService = AnimeDatabaseService();
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    dbService.getAnimeItemByName(widget.animeItem.name).then((value) {
      if (mounted) {
        setState(() {
          _favorite = value != null;
        });
      }
    });
  }

  //收藏改變狀態
  Future<void> _toggleFavorite() async {
    final yearMonthNotifier = ref.read(yearMonthProvider.notifier);
    final currentYearMonth = yearMonthNotifier.state;
    int result = 0;
    // 檢查 Widget 是否仍然掛載
    if (mounted) {
      if (_favorite) {
        result = await dbService.deleteAnimeItemByName(widget.animeItem.name);
      } else {
        // 目前不是收藏狀態 -> 嘗試收藏 (新增)，還要寫入年分，排序用
        var year = currentYearMonth.split('.')[0];
        AnimeItem newItemWithModifiedDate = widget.animeItem.copyWith(
          date: '$year/${widget.animeItem.date}',
        );
        result = await dbService.insertAnimeItem(newItemWithModifiedDate);
      }

      if (result > 0) {
        ToastUtils.showShortToast(context, _favorite ? '取消收藏成功' : '收藏成功');
        setState(() {
          _favorite = !_favorite;
        });
      } else if (result == 0 && !_favorite) {
        //已經存在資料，但為了狀態同步還是要更新
        setState(() {
          _favorite = true;
        });
      } else {
        ToastUtils.showShortToastError(context, '發生錯誤');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            // **設定 Modal 外部遮罩層的顏色** (可選，預設通常是半透明黑色)
            // barrierColor: Colors.black.withOpacity(0.6), // 範例：設定半透明黑色
            // **builder 參數：使用正確的語法返回要作為 Modal 內容的 Widget**
            builder: (BuildContext context) {
              return AnimeDetailModal(
                animeItem: widget.animeItem,
                favorite: _favorite,
                toggleFavorite: _toggleFavorite,
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左邊部分：圖片 (使用 SizedBox 設定固定大小)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                height: MediaQuery.of(context).size.height * 0.23,
                child: ClipRRect(
                  // 讓圖片有圓角
                  borderRadius: BorderRadius.circular(4.0),
                  child: CachedNetworkImage(
                    imageUrl:
                        widget.animeItem.img.startsWith('http')
                            ? widget.animeItem.img
                            : '$imageBaseUrl${widget.animeItem.img}',
                    fit: BoxFit.cover, // 填充設定大小並可能裁剪圖片
                    placeholder: (context, url) => const AppLoadingIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error, size: 40.0),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              // 圖片與文字之間的間隔
              // 右邊部分：文字內容 (使用 Expanded 讓其佔滿除了圖片之外的剩餘空間)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start, // 文字內容靠左對齊
                  children: [
                    // 標題 (name)
                    Text(
                      widget.animeItem.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Theme.of(context).textTheme.titleMedium?.fontSize ?? 16.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    // 標題與副標題之間的間隔
                    Text(
                      widget.animeItem.originalName,
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleSmall?.fontSize ?? 16,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.animeItem.date.split('/').length == 2)
                                AutoSizeText(
                                  '首播時間: ${widget.animeItem.date} ${widget.animeItem.time} ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else
                                AutoSizeText(
                                  ' ${widget.animeItem.date} ${widget.animeItem.time} ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              AutoSizeText(
                                '${showCarrier(widget.animeItem.carrier)} / 季度: ${widget.animeItem.season}',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child:
                              _favorite
                                  ? const Icon(Icons.favorite, color: Colors.grey)
                                  : const Icon(Icons.favorite_border, color: Colors.grey),
                        ),
                      ],
                    ),
                    AutoSizeText(
                      widget.animeItem.description,
                      style: Theme.of(context).textTheme.bodyMedium,
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
