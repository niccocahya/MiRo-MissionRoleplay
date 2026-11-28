import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miro_app/core/theme/miro_tokens.dart';
import 'package:miro_app/features/dev/gallery_sections_a.dart';
import 'package:miro_app/features/dev/gallery_sections_b.dart';
import 'package:miro_app/features/dev/gallery_sections_c.dart';

import '../../helpers/golden.dart';

/// Golden galeri per bagian (CODE_QUALITY §3, COMPONENTS §7).
///
/// Lebar 390 (desain) dan 360 (Android kelas bawah) dengan tinggi cukup
/// untuk seluruh bagian, plus 390 dengan teks 1.3×. Overflow = gagal.
void main() {
  final sections = <String, (Widget Function(), double)>{
    'buttons': (() => const GalleryButtons(), 1000),
    'cards': (() => const GalleryCards(), 1500),
    'form': (() => const GalleryForm(), 900),
    'status': (() => const GalleryStatus(), 1500),
    'mascot': (() => const GalleryMascot(), 750),
    'layout': (() => const GalleryLayout(), 1000),
  };

  for (final entry in sections.entries) {
    final (build, height) = entry.value;
    for (final v in [
      GoldenVariant('390', Size(390, height)),
      GoldenVariant('360', Size(360, height * 1.1)),
      GoldenVariant('390-text1.3', Size(390, height * 1.35), textScale: 1.3),
    ]) {
      testWidgets('galeri ${entry.key} @ ${v.name}', (tester) async {
        await pumpGolden(
          tester,
          Scaffold(
            backgroundColor: MiroColors.app,
            body: SingleChildScrollView(
              padding: MiroSpace.screen,
              child: build(),
            ),
          ),
          size: v.size,
          textScale: v.textScale,
        );
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile('../../goldens/gallery/${entry.key}.${v.name}.png'),
        );
      });
    }
  }
}
