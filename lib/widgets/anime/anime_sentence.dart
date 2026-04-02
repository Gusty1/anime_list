import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/widgets/app_loading_indicator.dart';
import 'package:anime_list/providers/hitokoto_provider.dart';

/// 首頁動漫名言元件
///
/// 使用 [hitokotoProvider] (FutureProvider) 管理載入狀態，
/// 透過 `ref.invalidate()` 實現刷新功能。
/// 內建 3 秒冷卻機制，防止使用者快速連點。
class AnimeSentence extends ConsumerStatefulWidget {
  const AnimeSentence({super.key});

  @override
  ConsumerState<AnimeSentence> createState() => _AnimeSentenceState();
}

class _AnimeSentenceState extends ConsumerState<AnimeSentence> {
  /// 冷卻時間（秒）
  static const int _cooldownSeconds = 3;

  /// 是否處於冷卻狀態
  bool _isCooldown = false;

  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// 刷新名言並啟動冷卻計時
  void _refresh() {
    ref.invalidate(hitokotoProvider);

    setState(() {
      _isCooldown = true;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: _cooldownSeconds), () {
      if (mounted) {
        setState(() {
          _isCooldown = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hitokotoAsync = ref.watch(hitokotoProvider);
    final bool isDisabled = hitokotoAsync.isLoading || _isCooldown;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左側引號裝飾
            Icon(
              Icons.format_quote,
              size: 32,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 8),

            // 名言內容
            Expanded(
              child: hitokotoAsync.when(
                loading: () => const AppLoadingIndicator(),
                error: (error, stack) => _buildErrorText(context),
                data: (hitokoto) {
                  if (hitokoto == null) return _buildErrorText(context);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        hitokoto.hitokoto,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '— ${hitokoto.from}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(width: 8),

            // 右側刷新按鈕
            IconButton.filledTonal(
              onPressed: isDisabled ? null : _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: '換一句',
            ),
          ],
        ),
      ),
    );
  }

  /// 建立錯誤提示文字
  Widget _buildErrorText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        '獲取動漫名言失敗。',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
