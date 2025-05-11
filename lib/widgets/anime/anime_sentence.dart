import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../app_loading_indicator.dart';
import '../../models/hitokoto.dart';
import '../../services/api_service.dart';
import '../../network/dio_client.dart';
import '../../constants.dart';

class AnimeSentence extends StatefulWidget {
  const AnimeSentence({super.key});

  @override
  State<AnimeSentence> createState() => _AnimeSentenceState();
}

class _AnimeSentenceState extends State<AnimeSentence> {
  late final ApiService _apiService;

  Hitokoto? _hitokoto;
  bool _isLoadingHitokoto = false;
  String? _errorMessage; // 用於顯示錯誤訊息

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient();
    _apiService = ApiService(dio: dioClient.dio);
    // 初次載入時自動獲取數據
    _fetchHitokoto();
  }

  // 獲取名言的異步函數
  Future<void> _fetchHitokoto() async {
    if (_isLoadingHitokoto) return;
    setState(() {
      _isLoadingHitokoto = true;
      _errorMessage = null; // 清除之前的錯誤訊息
      _hitokoto = null; // 清除之前的一言數據
    });

    final result = await _apiService.fetchHitokoto();
    setState(() {
      _hitokoto = result;
      if (result == null) {
        _errorMessage = "獲取動漫名言失敗。"; // 設置錯誤訊息
      }
    });
    //由於一言API太快速請求會有重複的，所以都延遲一秒再更新
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _hitokoto = result;
        _isLoadingHitokoto = false;
        if (result == null) {
          _errorMessage = "獲取動漫名言失敗。"; // 設置錯誤訊息
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      margin: const EdgeInsets.all(10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSecondaryFixed,
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                // 載入樣式
                if (_isLoadingHitokoto)
                  AppLoadingIndicator()
                // 錯誤訊息
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: AutoSizeText(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                // 正常
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
                            fontSize:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.fontSize,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryFixedVariant,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            // null就相當於 disabled
            onPressed: _isLoadingHitokoto ? null : _fetchHitokoto,
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.primary,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
                // 如果按鈕處於禁用狀態
                if (states.contains(WidgetState.disabled)) {
                  // 禁用返回錯誤顏色
                  return Colors.redAccent;
                }
                // 正常按鈕，返回正常背景色
                return Theme.of(context).colorScheme.secondaryContainer;
              }),
            ),
          ),
        ],
      ),
    );
  }
}
