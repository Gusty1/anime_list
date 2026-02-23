import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 回饋套件繁體中文在地化
class ZhTwFeedbackLocalizations extends FeedbackLocalizations {
  const ZhTwFeedbackLocalizations();

  @override
  String get submitButtonText => '送出';

  @override
  String get feedbackDescriptionText => '請描述您遇到的問題或建議：';

  @override
  String get draw => '繪製';

  @override
  String get navigate => '導覽';

  static const LocalizationsDelegate<FeedbackLocalizations> delegate =
      _ZhTwFeedbackLocalizationsDelegate();
}

class _ZhTwFeedbackLocalizationsDelegate
    extends LocalizationsDelegate<FeedbackLocalizations> {
  const _ZhTwFeedbackLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<FeedbackLocalizations> load(Locale locale) {
    return SynchronousFuture(const ZhTwFeedbackLocalizations());
  }

  @override
  bool shouldReload(_ZhTwFeedbackLocalizationsDelegate old) => false;
}
