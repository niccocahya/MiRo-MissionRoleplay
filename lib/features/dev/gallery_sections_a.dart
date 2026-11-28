import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/miro_tokens.dart';
import '../../shared/widgets/choice_card.dart';
import '../../shared/widgets/miro_button.dart';
import '../../shared/widgets/miro_card.dart';
import '../../shared/widgets/miro_chip.dart';
import '../../shared/widgets/miro_icon_button.dart';
import '../../shared/widgets/miro_text_link.dart';
import '../../shared/widgets/radio_card.dart';
import 'gallery_scaffold.dart';

/// Galeri bagian 1: tombol (DESIGN_SYSTEM §7.1, §7.2).
class GalleryButtons extends StatelessWidget {
  const GalleryButtons({super.key});

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return GallerySection(
      title: 'Tombol',
      children: [
        for (final v in MiroButtonVariant.values)
          MiroButton(label: v.name, onPressed: noop, variant: v),
        const MiroButton(label: 'Nonaktif', onPressed: null),
        MiroButton(label: 'Memuat', onPressed: noop, loading: true),
        Row(
          children: [
            MiroButton(
              label: 'Sedang',
              onPressed: noop,
              size: MiroButtonSize.m,
              expand: false,
            ),
            const SizedBox(width: MiroSpace.x3),
            MiroButton(
              label: 'Kecil',
              onPressed: noop,
              size: MiroButtonSize.s,
              expand: false,
              variant: MiroButtonVariant.secondary,
            ),
          ],
        ),
        MiroButton(
          label: 'Sudah!',
          onPressed: noop,
          variant: MiroButtonVariant.success,
          icon: PhosphorIcons.check(PhosphorIconsStyle.bold),
        ),
        Row(
          children: [
            MiroIconButton(
              icon: PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
              label: 'Kembali',
              onPressed: noop,
            ),
            const SizedBox(width: MiroSpace.x3),
            MiroIconButton(
              icon: PhosphorIcons.bell(PhosphorIconsStyle.bold),
              label: 'Notifikasi',
              size: 40,
              badge: true,
              onPressed: noop,
            ),
            const SizedBox(width: MiroSpace.x3),
            MiroIconButton(
              icon: PhosphorIcons.x(PhosphorIconsStyle.bold),
              label: 'Tutup',
              variant: MiroIconButtonVariant.ghost,
              iconColor: MiroColors.navy300,
              onPressed: noop,
            ),
            const SizedBox(width: MiroSpace.x3),
            const MiroIconButton(
              icon: PhosphorIconsBold.gear,
              label: 'Pengaturan (nonaktif)',
              onPressed: null,
            ),
          ],
        ),
        Wrap(
          spacing: MiroSpace.x4,
          children: [
            MiroTextLink(label: 'Lupa kata sandi?', onPressed: noop),
            MiroTextLink(
              label: 'Kelola anak',
              onPressed: noop,
              tone: MiroTextLinkTone.sky,
            ),
            MiroTextLink(
              label: 'Hapus profil',
              onPressed: noop,
              tone: MiroTextLinkTone.danger,
            ),
          ],
        ),
      ],
    );
  }
}

/// Galeri bagian 2: kartu dan pilihan (DESIGN_SYSTEM §7.3, §7.4, §7.8).
class GalleryCards extends StatefulWidget {
  const GalleryCards({super.key});

  @override
  State<GalleryCards> createState() => _GalleryCardsState();
}

class _GalleryCardsState extends State<GalleryCards> {
  final _picked = <String>{'Menggambar'};
  String _account = 'parent';
  String _child = 'Rafi';
  String _age = '6';
  int _shake = 0;

  void _toggle(String id) => setState(() {
        if (_picked.contains(id)) {
          _picked.remove(id);
        } else if (_picked.length >= 3) {
          _shake++; // M3: batas tercapai.
        } else {
          _picked.add(id);
        }
      });

  @override
  Widget build(BuildContext context) {
    final interests = <(String, IconData, MiroRole)>[
      ('Menggambar', PhosphorIconsBold.palette, MiroRole.artist),
      ('Membaca', PhosphorIconsBold.bookOpen, MiroRole.teacher),
      ('Musik', PhosphorIconsBold.musicNotes, MiroRole.doctor),
      ('Olahraga', PhosphorIconsBold.soccerBall, MiroRole.athlete),
    ];
    return GallerySection(
      title: 'Kartu dan pilihan',
      children: [
        for (final v in MiroCardVariant.values)
          MiroCard(
            variant: v,
            role: MiroRole.chef,
            child: Text(
              'MiroCard ${v.name}',
              style: MiroText.title.copyWith(
                color: v == MiroCardVariant.navy ? MiroColors.white : null,
              ),
            ),
          ),
        MiroCard(
          onTap: () {},
          child: const Text('Kartu bisa ditekan', style: MiroText.title),
        ),
        ChoiceCard(
          title: 'Orang Tua',
          subtitle: 'Bermain bersama si kecil di rumah.',
          icon: PhosphorIconsFill.usersThree,
          selected: _account == 'parent',
          onTap: () => setState(() => _account = 'parent'),
        ),
        ChoiceCard(
          title: 'Guru',
          subtitle: 'Kegiatan seru di kelas, tanpa data siswa.',
          icon: PhosphorIconsFill.chalkboardTeacher,
          selected: _account == 'teacher',
          onTap: () => setState(() => _account = 'teacher'),
        ),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (label, icon, role) in interests)
              ChoiceCard(
                layout: ChoiceCardLayout.grid,
                multi: true,
                title: label,
                icon: icon,
                color: role.base,
                softColor: role.soft,
                selected: _picked.contains(label),
                shakeSignal: _picked.contains(label) ? 0 : _shake,
                onTap: () => _toggle(label),
              ),
          ],
        ),
        for (final name in const ['Rafi', 'Nara'])
          RadioCard(
            title: name,
            subtitle: '6 tahun, level 6',
            selected: _child == name,
            onTap: () => setState(() => _child = name),
          ),
        Wrap(
          spacing: MiroSpace.x2,
          runSpacing: MiroSpace.x2,
          children: [
            for (final a in const ['2', '3', '4', '5', '6', '7'])
              MiroChip(
                label: a,
                selected: _age == a,
                onTap: () => setState(() => _age = a),
              ),
          ],
        ),
        const Wrap(
          spacing: MiroSpace.x2,
          runSpacing: MiroSpace.x2,
          children: [
            MiroPill(label: 'Misi pertama', tone: MiroPillTone.sky),
            MiroPill(label: 'Disarankan', tone: MiroPillTone.green),
            MiroPill(label: 'Emas', tone: MiroPillTone.amber),
            MiroPill(label: 'Rekor 21', tone: MiroPillTone.navy),
            MiroPill(label: 'Koki', role: MiroRole.chef),
            MiroPill(label: '15 mnt'),
          ],
        ),
      ],
    );
  }
}
