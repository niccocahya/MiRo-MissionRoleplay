import 'package:flutter/widgets.dart';

import '../app_info.dart';
import 'strings_en.dart';
import 'strings_id.dart';

/// Kamus teks UI ID/EN (DECISIONS §H5, CLAUDE.md aturan 11).
///
/// Cara pakai: `context.tr('common.next')`, dengan argumen
/// `context.tr('mission.startWith', args: {'n': 2})` untuk teks
/// `'MULAI DENGAN {n} ANAK'`. `{mascot}` selalu diganti `kMascotName`.
///
/// Layar baru wajib memakai ini. Layar lama yang masih menulis
/// `lang == 'id' ? … : …` dipindah saat layarnya disentuh.
abstract final class MiroStrings {
  static const supported = ['id', 'en'];

  static Map<String, String> of(String lang) =>
      lang == 'id' ? kStringsId : kStringsEn;

  /// Cari teks: bahasa aktif → Bahasa Indonesia → kunci itu sendiri (agar
  /// kunci yang lupa ditambahkan terlihat jelas saat diuji, bukan crash).
  static String lookup(
    String lang,
    String key, {
    Map<String, Object?> args = const {},
  }) {
    var text = of(lang)[key] ?? kStringsId[key] ?? key;
    text = text.replaceAll('{mascot}', kMascotName);
    args.forEach((name, value) {
      text = text.replaceAll('{$name}', '${value ?? ''}');
    });
    return text;
  }
}

/// Menyediakan bahasa aktif ke seluruh pohon widget. Dipasang sekali di
/// `MaterialApp.router(builder: …)` dari `languageProvider`.
class MiroLocaleScope extends InheritedWidget {
  const MiroLocaleScope({super.key, required this.lang, required super.child});

  final String lang;

  static String langOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MiroLocaleScope>()?.lang ??
      'id';

  @override
  bool updateShouldNotify(MiroLocaleScope oldWidget) => lang != oldWidget.lang;
}

extension MiroTr on BuildContext {
  /// Teks dari kamus untuk bahasa aktif.
  String tr(String key, {Map<String, Object?> args = const {}}) =>
      MiroStrings.lookup(MiroLocaleScope.langOf(this), key, args: args);

  /// Kode bahasa aktif (`'id'` atau `'en'`).
  String get lang => MiroLocaleScope.langOf(this);
}
