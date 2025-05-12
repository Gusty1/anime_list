import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_loading_indicator.dart';
import '../../models/hitokoto.dart';
import '../../providers/api_providers.dart';
import '../../utils/logger.dart';

// 首頁動漫句子，由於要使用riverpod提供的單一實例apiService，所以改為ConsumerStatefulWidget
class AnimeSentence extends ConsumerStatefulWidget {
  // <-- 修改為 ConsumerStatefulWidget
  const AnimeSentence({super.key});

  @override
  ConsumerState<AnimeSentence> createState() => _AnimeSentenceState();
}

class _AnimeSentenceState extends ConsumerState<AnimeSentence> {
  Hitokoto? _hitokoto; // 動漫名言model
  bool _isLoadingHitokoto = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHitokoto(); // 初始化呼叫獲取名言的方法
  }

  @override
  void dispose() {
    // 在 Widget 銷毀時，如果 _fetchHitokoto 裡面有定時器或其他需要取消的東西，在這裡處理
    // 例如：如果延遲的 Future.delayed 被保存了，在這裡取消它
    // 例如：如果你用 Future.delayed 返回的 Future 保存到了變量 _delayedFetch, 可以在 dispose 中 _delayedFetch?.cancel();
    super.dispose();
  }

  // 獲取名言的異步函數
  Future<void> _fetchHitokoto() async {
    // 如果已經在載入中，則退出
    if (_isLoadingHitokoto) return;

    // 使用 setState 更新 UI 狀態，顯示載入中
    setState(() {
      _isLoadingHitokoto = true;
      _errorMessage = null; // 清除之前的錯誤訊息
      _hitokoto = null; // 清除之前的一言數據
    });

    try {
      // 通過 ref.read() 獲取 Riverpod 提供的 ApiService 實例
      // ref 在 ConsumerState 中可以直接訪問
      final apiService = ref.read(apiServiceProvider);

      final result = await apiService.fetchHitokoto();

      // mounted 是 Flutter 核心框架中，State 類別的一個布林 (boolean) 屬性。
      if (!mounted) return; // <-- 重要：防止在 Widget 銷毀後呼叫 setState

      // AI說的，就先保留，但我覺得沒有問題
      // 如果你確保 result 已經包含最終數據，且只是為了延遲 UI 狀態更新，可以保留。
      // 但如果在延遲期間再次觸發了 _fetchHitokoto，可能會導致狀態混亂。
      // 通常情況下，不建議用 Future.delayed + setState 來控制流程或繞過 API 限制。
      // 處理這個問題的最佳方式可能是在 ApiService 層面實現防抖 (debounce) 或節流 (throttle)。
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return; // <-- 重要：再次檢查 mounted

        setState(() {
          _hitokoto = result;
          _isLoadingHitokoto = false;
          if (result == null) {
            _errorMessage = "獲取動漫名言失敗。";
          }
        });
      });
    } catch (e) {
      appLogger.e('Error in _fetchHitokoto: $e'); // Log 錯誤

      // 使用 setState 更新 UI 狀態，顯示錯誤訊息
      if (!mounted) return; // <-- 重要：檢查 mounted

      setState(() {
        _isLoadingHitokoto = false;
        _hitokoto = null;
        _errorMessage = "獲取動漫名言失敗: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.onPrimary, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                // 根據本地狀態顯示不同的內容
                if (_isLoadingHitokoto)
                  // 載入樣式 Widget
                  const AppLoadingIndicator() // 確保 AppLoadingIndicator 不需要 context 或 ref
                // 錯誤訊息
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: AutoSizeText(
                      _errorMessage!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  )
                // 正常顯示名言
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: AutoSizeText(
                          _hitokoto?.hitokoto ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AutoSizeText(
                          '╴${_hitokoto?.from ?? ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // 右側刷新按鈕
          IconButton(
            // 如果正在載入中，禁用按鈕 null就是禁用了
            onPressed: _isLoadingHitokoto ? null : _fetchHitokoto,
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.primary,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                // 根據按鈕狀態設置背景色
                if (states.contains(WidgetState.disabled)) {
                  return Theme.of(context).colorScheme.surface; // 禁用時使用表面色或灰色
                }
                return Theme.of(context).colorScheme.secondaryContainer; // 正常時使用次要容器色
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                if (states.contains(WidgetState.disabled)) {
                  return Theme.of(context).colorScheme.onSurface; // 禁用時使用表面色對比色
                }
                return Theme.of(context).colorScheme.onSecondaryContainer; // 正常時使用次要容器色對比色
              }),
            ),
          ),
        ],
      ),
    );
  }
}
