import 'package:get/get.dart';
import 'dart:ui';
import 'en_us.dart';
import 'tr_tr.dart';

final localeList = [const Locale('en', 'US'), const Locale('tr', 'TR')];

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en_US': enUS, 'tr_TR': trTR};
}
