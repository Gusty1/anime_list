import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:typed_data';
import '../../providers/year_month_provider.dart';
import '../../models/anime_item.dart';
import '../../constants.dart';
import '../app_loading_indicator.dart';
import '../../utils/show_carrier.dart';
import '../../utils/logger.dart';
import '../toast_utils.dart';

// 請求儲存圖片的權限
Future<bool> requestSavePermission() async {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  if (sdkInt >= 33) {
    // Android 13+ 使用 READ_MEDIA_IMAGES 權限
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  } else {
    // Android 12 以下使用舊的 STORAGE 權限
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  }
}

// 下載圖片並儲存到相簿
Future<bool> downloadAndSaveImage(String imageUrl, String fileName) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.bodyBytes),
        quality: 100,
        name: fileName,
      );
      return result['isSuccess'] ?? false;
    }
  } catch (e) {
    appLogger.e("儲存圖片錯誤", error: e);
  }
  return false;
}

// 處理圖片長按儲存邏輯
Future<void> handleImageLongPress(BuildContext context, String imageUrl, String animeName) async {
  final hasPermission = await requestSavePermission();
  if (!hasPermission) {
    if (!context.mounted) return;
    ToastUtils.showShortToastError(context, "儲存圖片失敗：未取得權限，請至應用程式設定開啟");
    return;
  }

  final fileName = "anime_${animeName}_${DateTime.now().millisecondsSinceEpoch}";
  final result = await downloadAndSaveImage(imageUrl, fileName);

  if (!context.mounted) return;
  if (result) {
    // 將這裡改為使用 ToastUtils.showShortToastSuccess
    ToastUtils.showShortToast(context, "圖片已儲存到相簿");
  } else {
    ToastUtils.showShortToastError(context, "儲存失敗，請稍後再試");
  }
}

// 動畫清單的詳細資訊彈窗
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

  String get _imageUrl =>
      widget.animeItem.img.startsWith('http')
          ? widget.animeItem.img
          : '$imageBaseUrl${widget.animeItem.img}';

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

  Future<void> _shareAnimeDetails() async {
    if (!mounted || _isSharing) return;

    setState(() {
      _isSharing = true;
    });

    final currentYearMonth = ref.read(yearMonthProvider);
    final year = currentYearMonth.split('.')[0];
    final shareText = [
      '${widget.animeItem.name} (${widget.animeItem.originalName})',
      "首播時間: '$year${widget.animeItem.date} ${widget.animeItem.time}",
      '${showCarrier(widget.animeItem.carrier)} / ${widget.animeItem.season}',
      if (widget.animeItem.official.isNotEmpty) '官方網站: ${widget.animeItem.official}',
      if (widget.animeItem.description.isNotEmpty) '\n${widget.animeItem.description}',
    ].where((line) => line.trim().isNotEmpty).join('\n');

    try {
      appLogger.i('正在從快取獲取圖片: $_imageUrl');
      final file = await DefaultCacheManager().getSingleFile(_imageUrl);
      final imageXFile = XFile(file.path, name: '${widget.animeItem.name}.png');
      await Share.shareXFiles([imageXFile], text: shareText);
    } catch (e, stackTrace) {
      appLogger.e('分享圖片時發生錯誤，將僅分享文字', error: e, stackTrace: stackTrace);
      if (mounted) {
        ToastUtils.showShortToastError(context, '圖片分享失敗，已改為分享文字');
      }
      await Share.share(shareText);
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 4.0),
            Text(
              widget.animeItem.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.animeItem.originalName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4.0),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.animeItem.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: GestureDetector(
                    onLongPress:
                        () => handleImageLongPress(context, _imageUrl, widget.animeItem.name),
                    child: PhotoView(
                      imageProvider: CachedNetworkImageProvider(_imageUrl),
                      minScale: PhotoViewComputedScale.contained * 0.8,
                      maxScale: PhotoViewComputedScale.covered * 2,
                      loadingBuilder: (context, event) => const AppLoadingIndicator(),
                    ),
                  ),
                ),
              ),
            );
          },
          onLongPress: () => handleImageLongPress(context, _imageUrl, widget.animeItem.name),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.height * 0.3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: CachedNetworkImage(
                imageUrl: _imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const AppLoadingIndicator(),
                errorWidget:
                    (context, url, error) =>
                    Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 40),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.animeItem.date} ${widget.animeItem.time}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${showCarrier(widget.animeItem.carrier)} / 季度: ${widget.animeItem.season}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4.0),
                  if (widget.animeItem.official.isNotEmpty)
                    InkWell(
                      onTap: _launchOfficialUrl,
                      child: Text(
                        '官方網站',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                      widget.toggleFavorite();
                    },
                    tooltip: '收藏動漫',
                  ),
                  IconButton(
                    icon:
                    _isSharing
                        ? const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.grey,
                      ),
                    )
                        : const Icon(Icons.share),
                    tooltip: '分享動漫資訊',
                    onPressed: _isSharing ? null : _shareAnimeDetails,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}