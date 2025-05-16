import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/anime_item.dart';
import '../../constants.dart';
import '../app_loading_indicator.dart';
import '../../utils/show_carrier.dart';
import '../../utils/logger.dart';
import '../toast_utils.dart';

class AnimeDetailModal extends StatefulWidget {
  final AnimeItem animeItem;
  final bool favorite;
  final Function toggleFavorite;

  const AnimeDetailModal({
    super.key,
    required this.animeItem,
    required this.favorite,
    required this.toggleFavorite,
  });

  @override
  // 創建並返回對應的 State 物件 (保持不變)
  _AnimeDetailModalState createState() => _AnimeDetailModalState();
}

// 創建對應的 State 類別
class _AnimeDetailModalState extends State<AnimeDetailModal> {
  // State 變數來追蹤圖片是否準備好分享 (保持不變)
  bool _isImageReady = false;
  bool _favorite = false;

  // 變數來管理圖片流的監聽器 (保持不變)
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  @override
  initState() {
    setState(() {
      _favorite = widget.favorite;
    });
  }

  // 將 _shareAnimeDetails 方法移到 State 類別中 (保持不變)
  Future<void> _shareAnimeDetails(BuildContext context) async {
    // 構建要分享的文字內容
    final String shareText = '''
      ${widget.animeItem.name} (${widget.animeItem.originalName})
      首播時間: ${widget.animeItem.date} ${widget.animeItem.time}
       ${showCarrier(widget.animeItem.carrier)} /  ${widget.animeItem.season}
      ${widget.animeItem.official.isNotEmpty ? '官方網站: ${widget.animeItem.official}' : ''}

      ${widget.animeItem.description.isNotEmpty ? '\n${widget.animeItem.description}' : ''}
    ''';
    final cleanShareText = shareText.split('\n').where((line) => line.trim().isNotEmpty).join('\n');

    // 構建圖片的網絡 URL
    final String imageUrl =
        widget.animeItem.img.startsWith('http')
            ? widget.animeItem.img
            : '$imageBaseUrl${widget.animeItem.img}';

    try {
      // 步驟 1: 下載圖片到暫存文件
      final response = await http.get(Uri.parse(imageUrl));

      // 檢查下載是否成功
      if (response.statusCode == 200) {
        // 獲取裝置的暫存目錄
        final directory = await getTemporaryDirectory();
        // 創建一個檔案物件，指定路徑和文件名
        final String fileName =
            '${widget.animeItem.name.replaceAll(RegExp(r'[^\w]'), '_')}_image.png';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);

        // 將下載到的圖片數據寫入到這個暫存檔案中
        await file.writeAsBytes(response.bodyBytes);

        // 步驟 2: 創建一個 XFile 物件指向這個暫存檔案
        final XFile imageXFile = XFile(filePath);

        // 步驟 3: 使用 shareXFiles 分享檔案和文字
        await Share.shareXFiles([imageXFile], text: cleanShareText);

        // 分享完成後，刪除暫存檔案
        await file.delete();
      } else {
        appLogger.i('分享失敗：無法下載圖片，狀態碼 ${response.statusCode}');
        ToastUtils.showShortToastError(context, '分享失敗');
        await Share.share(cleanShareText);
      }
    } catch (e) {
      appLogger.e('分享圖片時發生錯誤: $e');
      ToastUtils.showShortToastError(context, '分享失敗');
      await Share.share(cleanShareText);
    }
  }

  // Lifecycle 方法：當 Widget 被插入 Widget 樹時被呼叫 (保持不變)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImage();
  }

  // Lifecycle 方法：當 Widget 的配置改變時被呼叫 (保持不變)
  @override
  void didUpdateWidget(covariant AnimeDetailModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animeItem.img != oldWidget.animeItem.img) {
      _isImageReady = false;
      _imageInfo = null;
      _imageStream?.removeListener(
        ImageStreamListener(
          (info, sync) {},
          onError: (dynamic exception, StackTrace? stackTrace) {},
        ),
      );
      _loadImage();
    }
  }

  // 方法：載入圖片並監聽其狀態 (保持不變)
  void _loadImage() {
    // 構建圖片的網絡 URL，處理相對路徑
    final String imageUrl =
        widget.animeItem.img.startsWith('http')
            ? widget.animeItem.img
            : '$imageBaseUrl${widget.animeItem.img}';

    // 檢查圖片 URL 是否有效
    if (imageUrl.isEmpty) {
      setState(() {
        _isImageReady = false;
      });
      appLogger.w('Image URL is empty, cannot load image for sharing.');
      return;
    }

    final ImageProvider imageProvider = CachedNetworkImageProvider(imageUrl);

    // 解析圖片源，獲取圖片流
    _imageStream = imageProvider.resolve(createLocalImageConfiguration(context));

    // 添加一個監聽器到圖片流
    _imageStream!.addListener(
      ImageStreamListener(
        // 成功載入圖片時的呼叫回
        (info, synchronousCall) {
          setState(() {
            _imageInfo = info;
            _isImageReady = true; // 圖片載入成功，設定狀態為 true，啟用按鈕
          });
          appLogger.i('Image loaded successfully for sharing.');
        },
        // 圖片載入錯誤時的呼叫回
        onError: (dynamic exception, StackTrace? stackTrace) {
          setState(() {
            _isImageReady = false; // 圖片載入失敗，設定狀態為 false，禁用按鈕
          });
          appLogger.e('Error loading image for sharing: $exception');
        },
      ),
    );
  }

  @override
  void dispose() {
    // 移除圖片流的監聽器，防止內存洩漏
    _imageStream?.removeListener(
      ImageStreamListener(
        (info, sync) {}, // 提供空的呼叫回以正確移除監聽器
        onError: (dynamic exception, StackTrace? stackTrace) {}, // 提供空的呼叫回
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      // contentPadding: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),

      child: Container(
        // width: MediaQuery.of(context).size.width * 0.5, // 通常沒用
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          // 主要的內容 Column
          mainAxisSize: MainAxisSize.min, // Column 佔用最少空間
          crossAxisAlignment: CrossAxisAlignment.start, // 內容靠左對齊
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: PhotoView(
                                imageProvider: CachedNetworkImageProvider(
                                  widget.animeItem.img.startsWith('http')
                                      ? widget.animeItem.img
                                      : '$imageBaseUrl${widget.animeItem.img}',
                                ),
                                minScale: PhotoViewComputedScale.contained * 0.8,
                                maxScale: PhotoViewComputedScale.covered * 2,
                              ),
                            ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: CachedNetworkImage(
                        imageUrl:
                            widget.animeItem.img.startsWith('http')
                                ? widget.animeItem.img
                                : '$imageBaseUrl${widget.animeItem.img}',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const AppLoadingIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15.0),
                Expanded(
                  child: Column(
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
                      InkWell(
                        onTap: () async {
                          final Uri url = Uri.parse(widget.animeItem.official);
                          if (!await launchUrl(url)) {
                            ToastUtils.showShortToastError(context, '無法開啟網址');
                          }
                        },
                        child: Text(
                          '官方網站',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon:
                                _favorite
                                    ? Icon(Icons.favorite, color: Colors.red)
                                    : Icon(Icons.favorite_border, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _favorite = !_favorite;
                              });
                              if (widget.toggleFavorite != null) widget.toggleFavorite();
                            },
                            tooltip: '收藏動漫',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.share,
                              color:
                                  _isImageReady
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                            ),
                            tooltip: '分享動漫資訊',
                            onPressed:
                                _isImageReady
                                    ? () {
                                      _shareAnimeDetails(context);
                                    }
                                    : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              // **在固定高度的容器內部使用 SingleChildScrollView**
              child: SingleChildScrollView(
                // 只有這個區域可以滾動
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
}
