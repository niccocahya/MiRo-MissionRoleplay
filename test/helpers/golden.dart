import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:miro_app/core/l10n/tr.dart';
import 'package:miro_app/core/theme/miro_theme.dart';
import 'package:miro_app/core/theme/miro_tokens.dart';

/// Ukuran golden dasar (CODE_QUALITY §3): 390×844 logical, DPR 2, sama
/// dengan design/screens/*.png (780×1688).
const kGoldenScreen = Size(MiroSize.designWidth, MiroSize.designHeight);

/// Satu varian di matriks golden (RESPONSIVE §10).
class GoldenVariant {
  const GoldenVariant(this.name, this.size, {this.textScale = 1.0});

  final String name;
  final Size size;
  final double textScale;
}

/// Matriks wajib RESPONSIVE §10: 3 ukuran + 390×844 dengan teks 1.3×.
const kGoldenMatrix = [
  GoldenVariant('360x640', Size(360, 640)),
  GoldenVariant('390x844', kGoldenScreen),
  GoldenVariant('430x932', Size(430, 932)),
  GoldenVariant('390x844-text1.3', kGoldenScreen, textScale: 1.3),
];

bool _fontsLoaded = false;

/// Memuat Nunito dari aset supaya golden memakai font asli, bukan kotak
/// Ahem bawaan test. Dipanggil otomatis oleh `test/flutter_test_config.dart`.
Future<void> loadMiroFonts() async {
  if (_fontsLoaded) return;
  final nunito = FontLoader(MiroText.family);
  for (final file in const [
    'Nunito-SemiBold.ttf',
    'Nunito-Bold.ttf',
    'Nunito-ExtraBold.ttf',
    'Nunito-Black.ttf',
  ]) {
    nunito.addFont(rootBundle.load('assets/google_fonts/$file'));
  }
  await nunito.load();
  _fontsLoaded = true;
}

/// Penjaga overflow (RESPONSIVE §10, QA §9): overflow (`RenderFlex
/// overflowed`, dll.) membuat tes gagal.
///
/// Dua aturan binding test yang harus dipatuhi:
/// - `fail()`/`expect()` tidak boleh dipanggil di dalam `FlutterError.onError`
///   (tes menggantung), jadi overflow hanya dicatat di sana;
/// - `FlutterError.onError` harus sudah dikembalikan sebelum `expect()`,
///   jadi [check] mengembalikan handler dulu, baru memeriksa.
class OverflowGuard {
  OverflowGuard._(this._original);

  final FlutterExceptionHandler? _original;
  final List<String> _overflows = [];
  bool _restored = false;

  /// Mulai mencatat overflow. Handler asli dikembalikan otomatis di tearDown.
  static OverflowGuard install() {
    final guard = OverflowGuard._(FlutterError.onError);
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed') || text.contains('OVERFLOWING')) {
        guard._overflows.add(text.split('\n').first);
        return;
      }
      guard._original?.call(details);
    };
    addTearDown(guard._restore);
    return guard;
  }

  void _restore() {
    if (_restored) return;
    FlutterError.onError = _original;
    _restored = true;
  }

  /// Kembalikan handler asli, lalu gagal jika ada overflow.
  void check() {
    _restore();
    expect(_overflows, isEmpty, reason: 'Overflow terdeteksi (RESPONSIVE §10)');
  }
}

/// Memasang [child] di dalam MaterialApp bertema MiRO pada ukuran [size],
/// DPR 2, animasi dimatikan, dan overflow = gagal.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  Size size = kGoldenScreen,
  double textScale = 1.0,
  String lang = 'id',
  List<Override> overrides = const [],
}) async {
  final guard = OverflowGuard.install();
  tester.view
    ..physicalSize = size * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MiroTheme.light,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MiroLocaleScope(lang: lang, child: app!),
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  guard.check();
}

/// Membuat satu golden per varian di [kGoldenMatrix] untuk layar [id]
/// (mis. `'02-main'`). File: `test/goldens/<id>.<varian>.png`.
///
/// [goldensDir] adalah path relatif dari file tes ke `test/goldens/`.
void goldenMatrix(
  String id,
  Widget Function() build, {
  required String goldensDir,
  List<Override> overrides = const [],
  List<GoldenVariant> variants = kGoldenMatrix,
}) {
  for (final v in variants) {
    testWidgets('$id @ ${v.name}', (tester) async {
      await pumpGolden(
        tester,
        build(),
        size: v.size,
        textScale: v.textScale,
        overrides: overrides,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$goldensDir/$id.${v.name}.png'),
      );
    });
  }
}
