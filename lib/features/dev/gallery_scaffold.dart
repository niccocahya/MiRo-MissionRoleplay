import 'package:flutter/material.dart';

import '../../core/theme/miro_tokens.dart';

/// Satu bagian galeri: judul + widget berjarak 12, lebar penuh 390.
/// Dipakai juga oleh golden test per bagian (COMPONENTS §7).
class GallerySection extends StatelessWidget {
  const GallerySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MiroSpace.x6),
        Semantics(header: true, child: Text(title, style: MiroText.h2)),
        const SizedBox(height: MiroSpace.x3),
        for (final c in children) ...[c, const SizedBox(height: MiroSpace.x3)],
      ],
    );
  }
}
