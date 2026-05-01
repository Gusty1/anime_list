import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:anime_list/providers/year_month_provider.dart';
import 'package:anime_list/providers/favorite_provider.dart';
import 'package:anime_list/providers/anime_database_provider.dart';
import 'package:anime_list/models/anime_item.dart';
import 'package:anime_list/widgets/app_loading_indicator.dart';
import 'package:anime_list/utils/logger.dart';
import 'package:anime_list/widgets/toast_utils.dart';
import 'package:anime_list/utils/image_save_utils.dart';

/// 動畫詳細資訊頁面
///
/// 使用獨立 [Scaffold] 取代 Dialog，確保 [YoutubePlayerBuilder] 的
/// 全螢幕切換可以正確地推入新路由，不會有 overflow 警告。
///
/// [WidgetsBindingObserver] 在 app resume 時還原 system UI，
/// 防止舊版 Android 全螢幕退出後 status bar / nav bar 消失。
class AnimeDetailScreen extends ConsumerStatefulWidget {
  final AnimeItem animeItem;

  const AnimeDetailScreen({super.key, required this.animeItem});

  @override
  ConsumerState<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends ConsumerState<AnimeDetailScreen> with WidgetsBindingObserver {
  bool _isSharing = false;

  /// PV 播放器控制器，僅在有 pv 且 videoId 有效時建立
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initYoutubeController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ytController?.dispose();
    // 離開此頁面時確保還原 system UI，防止殘留 immersive 狀態
    _restoreSystemUI();
    super.dispose();
  }

  /// 監聽 app 生命週期，在 resume 時還原 system UI
  ///
  /// 舊版 Android 上 [youtube_player_flutter] 退出全螢幕後
  /// 有時不會正確還原 status bar / navigation bar，這裡作為兜底。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restoreSystemUI();
    }
  }

  /// 還原 system UI overlay（status bar + navigation bar）
  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// 初始化 YouTube 播放器控制器
  ///
  /// [YoutubePlayer.convertUrlToId] 同時支援：
  ///   - https://www.youtube.com/watch?v=XCyj9KKKjUI
  ///   - https://youtu.be/1EeNEWgRKVE
  void _initYoutubeController() {
    if (!widget.animeItem.hasPv) return;

    final videoId = YoutubePlayer.convertUrlToId(widget.animeItem.pv!);
    if (videoId == null) return;

    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        enableCaption: false,
        hideThumbnail: false,
        hideControls: false,
        endAt: 0,
      ),
    );
  }

  /// 切換收藏狀態
  Future<void> _toggleFavorite() async {
    if (!mounted) return;

    final isFavorite = ref.read(favoritedNamesProvider).contains(widget.animeItem.name);
    final currentYearMonth = ref.read(yearMonthProvider);
    final dbService = ref.read(animeDatabaseServiceProvider);
    int result = 0;

    if (isFavorite) {
      result = await dbService.deleteAnimeItemByName(widget.animeItem.name);
    } else {
      final year = currentYearMonth.split('.')[0];
      final newItem = widget.animeItem.copyWith(date: '$year/${widget.animeItem.date}');
      result = await dbService.insertAnimeItem(newItem);
    }

    final shouldRefresh = result > 0 || (result == 0 && !isFavorite);
    if (shouldRefresh) {
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

  /// 分享動漫詳細資訊（含圖片）
  Future<void> _shareAnimeDetails() async {
    if (!mounted || _isSharing) return;

    setState(() => _isSharing = true);

    final currentYearMonth = ref.read(yearMonthProvider);
    final year = currentYearMonth.split('.')[0];
    final imageUrl = widget.animeItem.fullImageUrl;
    final shareText = [
      '${widget.animeItem.name} (${widget.animeItem.originalName})',
      '首播時間: $year${widget.animeItem.date} ${widget.animeItem.time}',
      '${widget.animeItem.displayCarrier} / ${widget.animeItem.season}',
      if (widget.animeItem.official.isNotEmpty) '官方網站: ${widget.animeItem.official}',
      if (widget.animeItem.pv != null && widget.animeItem.pv!.isNotEmpty) 'PV: ${widget.animeItem.pv}',
      if (widget.animeItem.description.isNotEmpty) '\n${widget.animeItem.description}',
    ].where((line) => line.trim().isNotEmpty).join('\n');

    try {
      appLogger.d('正在從快取獲取圖片: $imageUrl');
      final file = await DefaultCacheManager().getSingleFile(imageUrl);
      final imageXFile = XFile(file.path, name: '${widget.animeItem.name}.png');
      await SharePlus.instance.share(ShareParams(files: [imageXFile], text: shareText));
    } catch (e, stackTrace) {
      appLogger.e('分享圖片時發生錯誤，將僅分享文字', error: e, stackTrace: stackTrace);
      if (mounted) {
        ToastUtils.showShortToastError(context, '圖片分享失敗，已改為分享文字');
      }
      await SharePlus.instance.share(ShareParams(text: shareText));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  /// 開啟官方網站
  Future<void> _launchOfficialUrl() async {
    if (!mounted) return;
    try {
      await launchUrl(Uri.parse(widget.animeItem.official));
    } catch (e) {
      appLogger.e('無法開啟網址: ${widget.animeItem.official}', error: e);
      if (mounted) ToastUtils.showShortToastError(context, '無法開啟此網址');
    }
  }

  /// 使用 EasyImageViewer 全螢幕顯示封面圖
  void _showFullScreenImage(String imageUrl) {
    _ytController?.pause();
    showImageViewer(context, CachedNetworkImageProvider(imageUrl), doubleTapZoomable: true, swipeDismissible: true);
  }

  // ── AppBar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme, bool isFavorite) {
    return AppBar(
      backgroundColor: colorScheme.inversePrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // 返回前先還原 system UI，防止影響上一頁
          _restoreSystemUI();
          Navigator.of(context).pop();
        },
      ),
      centerTitle: true,
      title: Text(
        widget.animeItem.name,
        style: Theme.of(context).textTheme.titleLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? colorScheme.error : null),
          tooltip: isFavorite ? '取消收藏' : '收藏動漫',
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon:
              _isSharing
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onSurface),
                  )
                  : const Icon(Icons.share_outlined),
          tooltip: '分享動漫資訊',
          onPressed: _isSharing ? null : _shareAnimeDetails,
        ),
      ],
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  /// 有 PV 時的 body：
  ///   - 播放器固定在頂部（16:9，由 library 決定高度）
  ///   - 其餘 meta 資訊固定顯示（不捲動）
  ///   - 只有描述文字區域可獨立捲動
  Widget _buildBodyWithPlayer(Widget player, String imageUrl, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 播放器（16:9，固定）
        player,

        // meta 資訊區（固定，不捲動）
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameTitle(colorScheme, textTheme),
              Text(
                widget.animeItem.originalName,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              _buildCoverImageRow(imageUrl, colorScheme, textTheme),
              const SizedBox(height: 10),
              _buildInfoChips(colorScheme, textTheme),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // 描述文字（獨立捲動區域）
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(widget.animeItem.description, style: textTheme.bodyMedium?.copyWith(height: 1.5)),
          ),
        ),
      ],
    );
  }

  /// 無 PV 時的 body：
  ///   - 封面圖固定在頂部
  ///   - meta 資訊固定顯示（不捲動）
  ///   - 只有描述文字區域可獨立捲動
  Widget _buildBodyWithCover(String imageUrl, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 封面圖（固定）
        _buildCoverImage(imageUrl, colorScheme),

        // meta 資訊區（固定，不捲動）
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameTitle(colorScheme, textTheme),
              Text(
                widget.animeItem.originalName,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              _buildInfoChips(colorScheme, textTheme),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // 描述文字（獨立捲動區域）
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(widget.animeItem.description, style: textTheme.bodyMedium?.copyWith(height: 1.5)),
          ),
        ),
      ],
    );
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(favoritedNamesProvider).contains(widget.animeItem.name);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = widget.animeItem.fullImageUrl;
    final hasPv = _ytController != null;

    // 無 PV：直接回傳普通 Scaffold
    if (!hasPv) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: _buildAppBar(colorScheme, isFavorite),
        body: _buildBodyWithCover(imageUrl, colorScheme, textTheme),
      );
    }

    // 有 PV：YoutubePlayerBuilder 必須包住整個 Scaffold，
    // 讓全螢幕時可以正確推入新路由，避免 overflow 警告。
    return YoutubePlayerBuilder(
      onExitFullScreen: _restoreSystemUI,
      player: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: colorScheme.primary,
        progressColors: ProgressBarColors(playedColor: colorScheme.primary, handleColor: colorScheme.primary),
        onEnded: (_) {
          // 播完後重置到開頭並暫停，避免顯示 YouTube 推薦影片畫面
          _ytController?.seekTo(Duration.zero);
          _ytController?.pause();
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: _buildAppBar(colorScheme, isFavorite),
          body: _buildBodyWithPlayer(player, imageUrl, colorScheme, textTheme),
        );
      },
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  /// 查看封面按鈕列（按鈕 + 長按提示文字）
  Widget _buildCoverImageRow(String imageUrl, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _showFullScreenImage(imageUrl),
          onLongPress: () => handleImageLongPress(context, imageUrl, widget.animeItem.name),
          icon: Icon(Icons.image_outlined, size: 16, color: colorScheme.primary),
          label: Text('查看封面', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            side: BorderSide(color: colorScheme.outlineVariant),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Text('長按可保存圖片', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  /// 頂部封面圖區域（沒有 PV 時顯示）
  Widget _buildCoverImage(String imageUrl, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageUrl),
      onLongPress: () => handleImageLongPress(context, imageUrl, widget.animeItem.name),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.30,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const AppLoadingIndicator(),
              errorWidget:
                  (context, url, error) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant, size: 48),
                  ),
            ),
          ),
          // 底部漸層遮罩
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
                  colors: [Colors.transparent, colorScheme.surface.withValues(alpha: 0.8)],
                ),
              ),
            ),
          ),
          // 右下角操作提示徽章
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => handleImageLongPress(context, imageUrl, widget.animeItem.name),
                  child: _ImageHintBadge(icon: Icons.download_outlined, label: '儲存', colorScheme: colorScheme),
                ),
                const SizedBox(width: 6),
                _ImageHintBadge(icon: Icons.zoom_in, label: '放大', colorScheme: colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 複製動漫名稱至剪貼簿
  void _copyName() {
    Clipboard.setData(ClipboardData(text: widget.animeItem.name));
    ToastUtils.showShortToast(context, '複製成功');
  }

  /// 動漫名稱標題
  ///
  /// 有官方網站時顯示為可點擊超連結（底線 + primary 色），點擊開啟網址，長按複製名稱。
  /// 無官方網站時顯示為一般文字，長按複製名稱。
  Widget _buildNameTitle(ColorScheme colorScheme, TextTheme textTheme) {
    final hasOfficial = widget.animeItem.official.isNotEmpty;

    final nameText = Text(
      widget.animeItem.name,
      style: textTheme.bodyLarge?.copyWith(
        color: hasOfficial ? colorScheme.primary : null,
        decoration: hasOfficial ? TextDecoration.underline : null,
        decorationColor: hasOfficial ? colorScheme.primary : null,
      ),
    );

    return InkWell(
      onTap: hasOfficial ? _launchOfficialUrl : null,
      onLongPress: _copyName,
      borderRadius: BorderRadius.circular(4),
      child: nameText,
    );
  }

  /// 資訊標籤列 (Chip)
  Widget _buildInfoChips(ColorScheme colorScheme, TextTheme textTheme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildChip(Icons.calendar_today, '${widget.animeItem.date} ${widget.animeItem.time}', colorScheme, textTheme),
        _buildChip(Icons.tv, widget.animeItem.displayCarrier, colorScheme, textTheme),
        _buildChip(Icons.looks, '季度: ${widget.animeItem.season}', colorScheme, textTheme),
      ],
    );
  }

  /// 單一 Chip 標籤
  Widget _buildChip(IconData icon, String label, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(label, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer)),
        ],
      ),
    );
  }
}

/// 封面圖右下角的操作提示徽章（如「儲存」、「放大」）
class _ImageHintBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _ImageHintBadge({required this.icon, required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurface),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurface)),
        ],
      ),
    );
  }
}
