import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miro_app/core/theme/miro_tokens.dart';

import '../../helpers/golden.dart';

/// Golden contoh (Fase 0): memastikan Nunito dan warna token benar-benar
/// terpakai di golden test. Bandingkan dengan DESIGN_SYSTEM §1 dan §2.
void main() {
  testWidgets('sampel token warna dan tipografi', (tester) async {
    await pumpGolden(
      tester,
      Scaffold(
        body: SafeArea(
          child: Padding(
            padding: MiroSpace.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: MiroSpace.x4),
                const Text('Misi selesai!', style: MiroText.display),
                const Text('Pilih peran', style: MiroText.h1),
                const Text('Siapa yang ikut main?', style: MiroText.h2),
                const Text('Membuat Bola Biskuit', style: MiroText.h3),
                const Text('Salad Pelangi', style: MiroText.title),
                const Text(
                  'Cuci tangan dulu. Masukkan biskuit ke plastik bersih.',
                  style: MiroText.bodyLg,
                ),
                const Text('Hari ini 10 dari 15 menit', style: MiroText.body),
                const Text('Koki 2/5', style: MiroText.caption),
                Text('LANJUT', style: MiroText.button(color: MiroColors.ink)),
                const SizedBox(height: MiroSpace.x6),
                Wrap(
                  spacing: MiroSpace.x2,
                  runSpacing: MiroSpace.x2,
                  children: [
                    for (final c in const [
                      MiroColors.navy900,
                      MiroColors.actionPrimary,
                      MiroColors.actionReward,
                      MiroColors.actionSuccess,
                      MiroColors.actionDanger,
                      MiroColors.sky300,
                      MiroColors.cream200,
                      MiroColors.line,
                    ])
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(MiroRadius.md),
                        ),
                      ),
                    for (final r in MiroRole.values)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: r.base,
                          borderRadius: BorderRadius.circular(MiroRadius.md),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../../goldens/00-tokens.png'),
    );
  });
}
