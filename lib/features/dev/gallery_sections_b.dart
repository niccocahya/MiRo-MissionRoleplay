import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/miro_tokens.dart';
import '../../shared/widgets/miro_avatar.dart';
import '../../shared/widgets/miro_controls.dart';
import '../../shared/widgets/miro_feedback.dart';
import '../../shared/widgets/miro_list.dart';
import '../../shared/widgets/miro_progress.dart';
import '../../shared/widgets/miro_text_field.dart';
import 'gallery_scaffold.dart';

/// Galeri bagian 3: form (DESIGN_SYSTEM §7.5, §7.6; HANDOFF 13, 15, 37).
class GalleryForm extends StatefulWidget {
  const GalleryForm({super.key});

  @override
  State<GalleryForm> createState() => _GalleryFormState();
}

class _GalleryFormState extends State<GalleryForm> {
  int _students = 22;
  int _groups = 4;
  String _mode = 'daftar';
  bool _reminder = true;
  bool _reduce = false;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Form',
      children: [
        MiroSegmented<String>(
          options: const [('daftar', 'Daftar'), ('masuk', 'Masuk')],
          value: _mode,
          onChanged: (v) => setState(() => _mode = v),
        ),
        const MiroTextField(
          label: 'Nama panggilan',
          icon: PhosphorIconsBold.user,
          hint: 'Contoh: Dinda',
          helper: 'Cukup nama panggilan',
        ),
        const MiroTextField(
          label: 'Email',
          icon: PhosphorIconsBold.envelopeSimple,
          error: 'Emailnya belum lengkap. Contoh: nama@gmail.com',
        ),
        const MiroTextField(
          label: 'Kata sandi',
          icon: PhosphorIconsBold.lockKey,
          obscure: true,
        ),
        Container(
          padding: const EdgeInsets.all(MiroSpace.x4),
          decoration: BoxDecoration(
            color: MiroColors.surface,
            borderRadius: BorderRadius.circular(MiroRadius.xl),
            border: Border.all(color: MiroColors.line, width: 2),
          ),
          child: MiroStepper(
            value: _students,
            min: 1,
            max: 60,
            caption: 'dari 24 siswa',
            decrementLabel: 'Kurangi siswa',
            incrementLabel: 'Tambah siswa',
            onChanged: (v) => setState(() => _students = v),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text('$_groups kelompok', style: MiroText.bodyStrong),
            ),
            MiroStepper(
              compact: true,
              value: _groups,
              min: 2,
              max: 10,
              onChanged: (v) => setState(() => _groups = v),
            ),
          ],
        ),
        Row(
          children: [
            MiroSwitch(
              value: _reminder,
              label: 'Pengingat',
              onChanged: (v) => setState(() => _reminder = v),
            ),
            const SizedBox(width: MiroSpace.x4),
            MiroSwitch(
              value: _reduce,
              label: 'Kurangi animasi',
              onChanged: (v) => setState(() => _reduce = v),
            ),
            const SizedBox(width: MiroSpace.x4),
            const MiroSwitch(value: true, onChanged: null, label: 'Nonaktif'),
          ],
        ),
      ],
    );
  }
}

/// Galeri bagian 4: progres, avatar, daftar, umpan balik.
class GalleryStatus extends StatelessWidget {
  const GalleryStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Progres, avatar, daftar',
      children: [
        const SegmentBar(current: 2, steps: 7),
        const MiroProgressBar(value: 0.5),
        const MiroProgressBar(
          value: 0.66,
          color: MiroColors.coral500,
          track: MiroColors.navy700,
          height: 10,
        ),
        Wrap(
          spacing: MiroSpace.x3,
          runSpacing: MiroSpace.x3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const MiroAvatar(size: 52),
            MiroAvatar(size: 52, background: kAvatarColors[1]),
            const MiroAvatar(
              size: 52,
              initial: 'Dinda',
              background: MiroColors.coral100,
            ),
            const MiroAvatar(size: 52, ring: MiroColors.coral500),
            AvatarStack(
              avatars: [
                for (final c in kAvatarColors.take(5))
                  MiroAvatar(size: 28, background: c, border: true),
              ],
              max: 3,
            ),
          ],
        ),
        MiroListGroup(
          title: 'Pengingat',
          children: [
            MiroListRow(
              icon: PhosphorIconsBold.bell,
              tone: MiroListTone.amber,
              title: 'Pengingat harian',
              subtitle: 'Setiap hari jam 16.00',
              trailing: MiroSwitch(value: true, onChanged: (_) {}),
            ),
            MiroListRow(
              icon: PhosphorIconsBold.target,
              title: 'Target harian',
              value: '15 menit',
              onTap: () {},
            ),
            MiroListRow(
              icon: PhosphorIconsBold.trash,
              tone: MiroListTone.red,
              title: 'Hapus akun keluarga',
              danger: true,
              onTap: () {},
            ),
          ],
        ),
        const MiroBanner(
          message: 'Kamu sedang offline. Foto diunggah otomatis nanti.',
          icon: PhosphorIconsBold.wifiSlash,
        ),
        const MiroBanner(
          tone: MiroBannerTone.success,
          title: 'Link terkirim',
          message: 'Cek email kamu. Kirim ulang dalam 60 detik.',
        ),
        const MiroBanner(
          tone: MiroBannerTone.danger,
          message: 'Foto lebih dari 15 MB. Pilih foto lain.',
        ),
        const MiroBanner(
          tone: MiroBannerTone.cream,
          message: 'Hanya untuk Memori kelas, tanpa nama murid.',
        ),
        Container(
          padding: const EdgeInsets.all(MiroSpace.x4),
          decoration: BoxDecoration(
            color: MiroColors.navy900,
            borderRadius: BorderRadius.circular(MiroRadius.xxl),
          ),
          child: const CodeBoxes(code: 'MR0482'),
        ),
        const Row(
          children: [
            MiroSkeleton(width: 52, height: 52, circle: true),
            SizedBox(width: MiroSpace.x3),
            Expanded(child: MiroSkeleton(height: 20)),
          ],
        ),
        MiroEmptyState(
          title: 'Album masih kosong',
          body: 'Mainkan misi pertama dan abadikan keseruannya.',
          steps: const ['Pilih misi', 'Main bersama', 'Ambil foto'],
          actionLabel: 'Mulai misi pertama',
          onAction: () {},
        ),
      ],
    );
  }
}
