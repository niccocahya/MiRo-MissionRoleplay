import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/miro_tokens.dart';
import '../../shared/widgets/layout/miro_layout.dart';
import '../../shared/widgets/miro_controls.dart';
import 'gallery_sections_a.dart';
import 'gallery_sections_b.dart';
import 'gallery_sections_c.dart';

/// Galeri widget (COMPONENTS §7). Hanya terdaftar di router saat
/// `kDebugMode`; dipakai untuk memeriksa semua varian dan state widget di
/// lebar 390, dan sebagai sumber golden test per bagian.
class GalleryPage extends ConsumerWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduce = ref.watch(settingsProvider.select((s) => s.reduceMotion));
    return MiroScaffold(
      header: MiroPageHeader(
        title: context.tr('dev.galleryTitle'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('dev.reduceMotion'), style: MiroText.label),
            const SizedBox(width: MiroSpace.x2),
            MiroSwitch(
              value: reduce ?? false,
              label: context.tr('dev.reduceMotion'),
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setReduceMotion(v),
            ),
          ],
        ),
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GalleryButtons(),
          GalleryCards(),
          GalleryForm(),
          GalleryStatus(),
          GalleryMascot(),
          GalleryLayout(),
          SizedBox(height: MiroSpace.x10),
        ],
      ),
    );
  }
}
