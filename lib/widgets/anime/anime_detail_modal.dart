import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../providers/year_month_provider.dart';
import '../../models/anime_item.dart';
import '../../constants.dart';
import '../app_loading_indicator.dart';
import '../../utils/show_carrier.dart';
import '../../utils/logger.dart';
import '../toast_utils.dart';

//動畫清單的detail modal
class AnimeDetailModal extends ConsumerStatefulWidget {
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
  ConsumerState createState() => _AnimeDetailModalState();
}

// 創建對應的 State 類別
class _AnimeDetailModalState extends ConsumerState<AnimeDetailModal> {
  // State 變數來追蹤圖片是否準備好分享
  bool _isImageReady = false;
  bool _favorite = false;
  // 【改動】新增一個旗標來追蹤 State 是否正在被銷毀
  bool _isDisposing = false;

  // 變數來管理圖片流的監聽器 (保持不變)
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  @override
  void initState() {
    super.initState();
    setState(() {
      _favorite = widget.favorite;
    });
  }

  Future<void> _shareAnimeDetails(BuildContext context) async {
    if(!mounted || _isDisposing) return; // 【改動】在方法開頭檢查 isDisposing

    final currentYearMonth = ref.read(yearMonthProvider);
    final year = currentYearMonth.split('.')[0];
    // 構建要分享的文字內容
    final String shareText = '''
      ${widget.animeItem.name} (${widget.animeItem.originalName})
      首播時間: '$year${widget.animeItem.date} ${widget.animeItem.time}
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
    // 【改動】在 didChangeDependencies 中呼叫 _loadImage，並檢查 isDisposing
    if(!_isDisposing) {
      _loadImage();
    }
  }

  // Lifecycle 方法：當 Widget 的配置改變時被呼叫 (保持不變)
  @override
  void didUpdateWidget(covariant AnimeDetailModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(!mounted || _isDisposing) return; // 【改動】在方法開頭檢查 isDisposing
    if (widget.animeItem.img != oldWidget.animeItem.img) {
      _isImageReady = false;
      _imageInfo = null;
      // 【改動】移除舊監聽器前先檢查 _imageStream 是否為 null
      if (_imageStream != null) {
        _imageStream?.removeListener(
          ImageStreamListener(
                (info, sync) {},
            onError: (dynamic exception, StackTrace? stackTrace) {},
          ),
        );
        _imageStream = null; // 【改動】設置為 null
      }
      _loadImage();
    }
  }

  // 方法：載入圖片並監聽其狀態
  void _loadImage() {
    // 【改動】在方法開頭檢查 isDisposing
    if(!mounted || _isDisposing) {
      appLogger.d('loadImage called when not mounted or disposing. Returning.');
      return;
    }

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
    // 【改動】先移除舊的監聽器，如果有的話
    if (_imageStream != null) {
      _imageStream?.removeListener(
        ImageStreamListener(
              (info, sync) {},
          onError: (dynamic exception, StackTrace? stackTrace) {},
        ),
      );
    }
    _imageStream = imageProvider.resolve(createLocalImageConfiguration(context));

    // 添加一個監聽器到圖片流
    _imageStream!.addListener(
      ImageStreamListener(
        // 成功載入圖片時的呼叫回
            (info, synchronousCall) {
          // 【改動】檢查 mounted 和 isDisposing
          if(!mounted || _isDisposing) {
            appLogger.d('Image success callback fired when not mounted or disposing. Returning.');
            return;
          }
          setState(() {
            _imageInfo = info;
            _isImageReady = true; // 圖片載入成功，設定狀態為 true，啟用按鈕
          });
          appLogger.i('Image loaded successfully for sharing.');
        },
        // 圖片載入錯誤時的呼叫回
        onError: (dynamic exception, StackTrace? stackTrace) {
          appLogger.d('Image error callback fired. mounted (start): $mounted, isDisposing (start): $_isDisposing');

          // 【改動】立即移除監聽器，防止重複回呼
          if (_imageStream != null) {
            _imageStream?.removeListener(
              ImageStreamListener(
                    (info, sync) {},
                onError: (dynamic e, StackTrace? s) {},
              ),
            );
            _imageStream = null; // 【改動】設置為 null
          }

          // 【改動】檢查 mounted 和 isDisposing，如果任一個為 true，就直接返回
          if (!mounted || _isDisposing) {
            appLogger.d('Mounted is false or isDisposing is true, returning from error callback.');
            return;
          }

          // 【改動】如果 mounted 是 true 且不是正在銷毀，將 setState 安排到下一個微任務
          appLogger.d('Mounted is true and not disposing, scheduling setState in microtask.');
          Future.microtask(() {
            // 【改動】在微任務中再次檢查 mounted 和 isDisposing
            if (!mounted || _isDisposing) {
              appLogger.d('Mounted is now false or isDisposing is true in microtask, cancelling setState.');
              return;
            }
            appLogger.d('Calling setState via microtask in error callback.');
            try {
              setState(() {
                _isImageReady = false;
              });
              appLogger.i('Successfully called setState in microtask after image error.');
            } catch (e) {
              // 【改動】如果加了微任務還是出錯，捕獲並記錄
              appLogger.e('Error calling setState in microtask after image error: $e');
            }
          });

          // 【改動】在原始回呼的最後記錄原始錯誤
          appLogger.e('Original Error loading image for sharing: $exception');
        },
      ),
    );
  }

  @override
  void dispose() {
    // 【改動】在銷毀過程開始時設定旗標
    _isDisposing = true;
    // 【改動】移除圖片流的監聽器，防止內存洩漏，並檢查 _imageStream 是否為 null
    if (_imageStream != null) {
      _imageStream?.removeListener(
        ImageStreamListener(
              (info, sync) {},
          onError: (dynamic exception, StackTrace? stackTrace) {},
        ),
      );
      _imageStream = null; // 【改動】設置為 null
    }
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
          mainAxisSize: MainAxisSize.max, // Column 佔用最少空間
          crossAxisAlignment: CrossAxisAlignment.start, // 內容靠左對齊
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    if(!mounted || _isDisposing) return; // 【改動】在方法開頭檢查 isDisposing
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
                        errorWidget:
                            (context, url, error) => Icon(
                          Icons.error,
                          color: Theme.of(context).colorScheme.error,
                          size: Theme.of(context).textTheme.headlineLarge?.fontSize ?? 20,
                        ),
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
                          if(!mounted || _isDisposing) return; // 【改動】在方法開頭檢查 isDisposing
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
                              if(!mounted || _isDisposing) return; // 【改動】在方法開頭檢查 isDisposing
                              setState(() {
                                _favorite = !_favorite;
                              });
                              widget.toggleFavorite();
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
                              if(!mounted || _isDisposing) return; // 【改動】在方法開頭檢查 isDisposing
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