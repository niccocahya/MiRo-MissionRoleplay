import 'package:flutter/material.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/miro_tokens.dart';

/// Galeri widget (COMPONENTS §7). Hanya terdaftar di router saat
/// `kDebugMode`; dipakai untuk memeriksa semua varian dan state widget,
/// dan sebagai sumber golden test per bagian.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiroColors.app,
      body: SafeArea(
        child: ListView(
          padding: MiroSpace.screen,
          children: [
            const SizedBox(height: MiroSpace.x6),
            Text(context.tr('dev.galleryTitle'), style: MiroText.h1),
          ],
        ),
      ),
    );
  }
}
