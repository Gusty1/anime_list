import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:typed_data';
import 'package:anime_list/providers/year_month_provider.dart';
import 'package:anime_list/models/anime_item.dart';
import 'package:anime_list/widgets/app_loading_indicator.dart';
import 'package:anime_list/utils/logger.dart';
import 'package:anime_list/widgets/toast_utils.dart';

/// 請求儲存圖片的權限（依 Android 版本使用不同的權限）
Future<bool> requestSavePermission() async {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  if (sdkInt >= 33) {
    // Android 13+ 使用 READ_MEDIA_IMAGES
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  } else {
    // Android 12 以下使用 STORAGE
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  }
}

/// 下載圖片並儲存到相簿（從快取讀取已下載的圖片）
Future<bool> downloadAndSaveImage(String imageUrl, String fileName) async {
  try {
    // 從快取取得圖片檔案（CachedNetworkImage 已經快取過）
    final file = await DefaultCacheManager().getSingleFile(imageUrl);
    final bytes = await file.readAsBytes();

    final result = await ImageGallerySaverPlus.saveImage(
      Uint8List.fromList(bytes),
      quality: 100,
      name: fileName,
    );

    if (result is Map) {
      return (result['isSuccess'] as bool?) ?? false;
    }
    return false;
  } catch (e) {
    appLogger.e('儲存圖片錯誤', error: e);
    return false;
  }
}

/// 處理圖片長按儲存邏輯
Future<void> handleImageLongPress(
  BuildContext context,
  String imageUrl,
  String animeName,
) async {
  final hasPermission = await requestSavePermission();
  if (!hasPermission) {
    if (!context.mounted) return;
    ToastUtils.showShortToastError(context, '儲存圖片失敗：未取得權限，請至應用程式設定開啟');
    return;
  }

  final fileName =
      'anime_${animeName}_${DateTime.now().millisecondsSinceEpoch}';
  final result = await downloadAndSaveImage(imageUrl, fileName);

  if (!context.mounted) return;
  if (result) {
    ToastUtils.showShortToast(context, '圖片已儲存到相簿');
  } else {
    ToastUtils.showShortToastError(context, '儲存失敗，請稍後再試');
  }
}

/// 動畫詳細資訊彈窗
///
/// 顯示封面大圖、完整資訊、收藏按鈕、分享按鈕和官方網站連結。
/// 點擊封面圖使用 [EasyImageViewer] 在 overlay 中全螢幕放大，無需切換頁面。
class AnimeDetailModal extends ConsumerStatefulWidget {
  final AnimeItem animeItem;
  final bool favorite;
  final VoidCallback toggleFavorite;

  const AnimeDetailModal({
    super.key,
    required this.animeItem,
    required this.favorite,
    required this.toggleFavorite,
  });

  @override
  ConsumerState<AnimeDetailModal> createState() => _AnimeDetailModalState();
}

class _AnimeDetailModalState extends ConsumerState<AnimeDetailModal> {
  late bool _isFavorite;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.favorite;
  }

  @override
  void didUpdateWidget(covariant AnimeDetailModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.favorite != oldWidget.favorite) {
      setState(() {
        _isFavorite = widget.favorite;
      });
    }
  }

  /// 分享動漫詳細資訊（含圖片）
  Future<void> _shareAnimeDetails() async {
    if (!mounted || _isSharing) return;

    setState(() {
      _isSharing = true;
    });

    final currentYearMonth = ref.read(yearMonthProvider);
    final year = currentYearMonth.split('.')[0];
    final imageUrl = widget.animeItem.fullImageUrl;
    final shareText = [
      '${widget.animeItem.name} (${widget.animeItem.originalName})',
      "首播時間: '$year${widget.animeItem.date} ${widget.animeItem.time}",
      '${widget.animeItem.displayCarrier} / ${widget.animeItem.season}',
      if (widget.animeItem.official.isNotEmpty)
        '官方網站: ${widget.animeItem.official}',
      if (widget.animeItem.description.isNotEmpty)
        '\n${widget.animeItem.description}',
    ].where((line) => line.trim().isNotEmpty).join('\n');

    try {
      appLogger.d('正在從快取獲取圖片: $imageUrl');
      final file = await DefaultCacheManager().getSingleFile(imageUrl);
      final imageXFile = XFile(file.path, name: '${widget.animeItem.name}.png');
      await SharePlus.instance.share(
        ShareParams(files: [imageXFile], text: shareText),
      );
    } catch (e, stackTrace) {
      appLogger.e('分享圖片時發生錯誤，將僅分享文字', error: e, stackTrace: stackTrace);
      if (mounted) {
        ToastUtils.showShortToastError(context, '圖片分享失敗，已改為分享文字');
      }
      await SharePlus.instance.share(ShareParams(text: shareText));
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  /// 開啟官方網站
  Future<void> _launchOfficialUrl() async {
    if (!mounted) return;
    try {
      await launchUrl(Uri.parse(widget.animeItem.official));
    } catch (e) {
      appLogger.e('無法開啟網址: ${widget.animeItem.official}', error: e);
      if (mounted) {
        ToastUtils.showShortToastError(context, '無法開啟此網址');
      }
    }
  }

  /// 下載圖片到相簿
  Future<void> _handleDownload(BuildContext context, String imageUrl) async {
    await handleImageLongPress(context, imageUrl, widget.animeItem.name);
  }

  /// 使用 EasyImageViewer 全螢幕顯示圖片（overlay，不跳頁）
  void _showFullScreenImage(String imageUrl) {
    final imageProvider = CachedNetworkImageProvider(imageUrl);
    showImageViewer(
      context,
      imageProvider,
      doubleTapZoomable: true,
      swipeDismissible: true,
      onViewerDismissed: () {
        appLogger.d('Image viewer dismissed');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = widget.animeItem.fullImageUrl;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 頂部封面圖（可點擊放大、長按儲存）──
            _buildCoverImage(context, imageUrl, colorScheme),

            // ── 內容區域 ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 動畫名稱
                    Text(
                      widget.animeItem.name,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // 原作名
                    Text(
                      widget.animeItem.originalName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // 資訊標籤列（Chip 風格）
                    _buildInfoChips(context, colorScheme, textTheme),
                    const SizedBox(height: 10),

                    // 官方網站連結
                    if (widget.animeItem.official.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: _launchOfficialUrl,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '官方網站',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 簡介（可捲動）
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          widget.animeItem.description,
                          style: textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ),
                    ),

                    // ── 底部操作列 ──
                    _buildActionBar(colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 頂部封面圖區域
  Widget _buildCoverImage(
    BuildContext context,
    String imageUrl,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageUrl),
      onLongPress:
          () => handleImageLongPress(context, imageUrl, widget.animeItem.name),
      child: Stack(
        children: [
          // 封面圖
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.25,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const AppLoadingIndicator(),
              errorWidget:
                  (context, url, error) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                  ),
            ),
          ),

          // 底部漸層遮罩（讓標題文字在圖片上更易讀）
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // 操作提示圖示列
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 下載圖片按鈕
                GestureDetector(
                  onTap: () => _handleDownload(context, imageUrl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 16,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '儲存',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 放大提示
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in,
                        size: 16,
                        color: colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '放大',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 資訊標籤列 (Chip)
  Widget _buildInfoChips(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildChip(
          Icons.calendar_today,
          '${widget.animeItem.date} ${widget.animeItem.time}',
          colorScheme,
          textTheme,
        ),
        _buildChip(
          Icons.tv,
          widget.animeItem.displayCarrier,
          colorScheme,
          textTheme,
        ),
        _buildChip(
          Icons.looks,
          '季度: ${widget.animeItem.season}',
          colorScheme,
          textTheme,
        ),
      ],
    );
  }

  /// 單一 Chip 標籤
  Widget _buildChip(
    IconData icon,
    String label,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// 底部操作列
  Widget _buildActionBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 收藏按鈕
          IconButton.filledTonal(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color:
                  _isFavorite
                      ? Colors.redAccent
                      : colorScheme.onSecondaryContainer,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              widget.toggleFavorite();
            },
            tooltip: _isFavorite ? '取消收藏' : '收藏動漫',
          ),
          const SizedBox(width: 8),

          // 分享按鈕
          IconButton.filledTonal(
            icon:
                _isSharing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
                    )
                    : const Icon(Icons.share_outlined),
            tooltip: '分享動漫資訊',
            onPressed: _isSharing ? null : _shareAnimeDetails,
          ),
        ],
      ),
    );
  }
}
