import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/miro_tokens.dart';
import '../../shared/icons/feeling_face.dart';
import '../../shared/icons/game_icons.dart';
import '../../shared/widgets/layout/miro_layout.dart';
import '../../shared/widgets/layout/miro_nav.dart';
import '../../shared/widgets/mascot/mascot.dart';
import '../../shared/widgets/miro_avatar.dart';
import '../../shared/widgets/miro_button.dart';
import '../../shared/widgets/miro_feedback.dart';
import '../../shared/widgets/miro_progress.dart';
import '../../shared/widgets/miro_sheet.dart';
import '../../shared/widgets/motion/miro_motion.dart';
import 'gallery_scaffold.dart';

/// Galeri bagian 5: maskot dan ikon kustom (COMPONENTS §5.3, §5.4).
class GalleryMascot extends StatelessWidget {
  const GalleryMascot({super.key});

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Maskot dan ikon',
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MascotImage(pose: MascotPose.wave, height: 120),
            SizedBox(width: MiroSpace.x2),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: SpeechBubble(
                  text: 'Hai, aku Mink! Siapa yang akan bermain bersamaku?',
                ),
              ),
            ),
          ],
        ),
        const Wrap(
          spacing: MiroSpace.x2,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            MascotImage(pose: MascotPose.main, height: 80),
            MascotImage(pose: MascotPose.sad, height: 80),
            MascotImage(pose: MascotPose.chefWin, height: 80),
            MascotImage(pose: MascotPose.doctorWin, height: 80),
          ],
        ),
        const MascotTip(
          title: 'Tips untuk Ayah/Bunda',
          body: 'Libatkan indra: "Coba rasakan, remahannya kasar atau halus?"',
          collapsible: true,
        ),
        Wrap(
          spacing: MiroSpace.x3,
          runSpacing: MiroSpace.x3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final s in CrystalState.values)
              StreakCrystal(state: s, size: 32),
            const FishIcon(size: 28),
            const TipIcon(size: 28),
            const SnowflakeIcon(size: 28),
            const PotIcon(color: MiroColors.coral500),
            const CrownIcon(width: 56),
            const ChestIcon(width: 56),
            const ChestIcon(width: 56, open: true),
          ],
        ),
        Wrap(
          spacing: MiroSpace.x2,
          children: [
            for (var i = 1; i <= 5; i++) FeelingFace(level: i, size: 48),
          ],
        ),
      ],
    );
  }
}

/// Galeri bagian 6: layout, sheet, dan animasi.
class GalleryLayout extends StatefulWidget {
  const GalleryLayout({super.key});

  @override
  State<GalleryLayout> createState() => _GalleryLayoutState();
}

class _GalleryLayoutState extends State<GalleryLayout> {
  int _tab = 0;
  int _fish = 340;
  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Layout, sheet, animasi',
      children: [
        const MiroPageHeader(title: 'Pengaturan'),
        MiroTopBar(
          profileName: 'Rafi',
          profileAvatar: const MiroAvatar(size: 34),
          fish: _fish,
          hasUnread: true,
          onSearch: () {},
          onSwitchProfile: () {},
          onNotifications: () {},
        ),
        MiroBottomNav(
          index: _tab,
          onTap: (i) => setState(() => _tab = i),
          profileAvatar: (active) => MiroAvatar(
            size: 30,
            initial: 'Dinda',
            background: active ? MiroColors.coral500 : MiroColors.navy100,
            initialColor: active ? MiroColors.white : MiroColors.ink3,
          ),
        ),
        MiroButton(
          label: 'Buka sheet',
          variant: MiroButtonVariant.secondary,
          onPressed: () => showMiroSheet<void>(
            context,
            child: const MiroSheet(
              title: 'Main bersama siapa?',
              showClose: true,
              child: Text('Isi sheet', style: MiroText.bodyLg),
            ),
          ),
        ),
        MiroButton(
          label: 'Buka konfirmasi keluar',
          variant: MiroButtonVariant.secondary,
          onPressed: () => showMiroSheet<void>(
            context,
            child: MiroAlertSheet(
              title: 'Yakin mau berhenti?',
              body: 'Rafi sudah sampai langkah 2 dari 3. Kalau berhenti '
                  'sekarang, progres misi ini belum tersimpan.',
              illustration:
                  const MascotImage(pose: MascotPose.sad, height: 120),
              extra: const SegmentBar(current: 2, steps: 3),
              safeLabel: 'Lanjut main',
              dangerLabel: 'Berhenti',
              onSafe: () => Navigator.of(context).pop(),
              onDanger: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        MiroButton(
          label: 'Tampilkan toast',
          variant: MiroButtonVariant.secondary,
          onPressed: () => showMiroToast(context, 'Foto tersimpan'),
        ),
        MiroButton(
          label: 'Ulang animasi (+10 ikan)',
          variant: MiroButtonVariant.reward,
          icon: PhosphorIconsBold.arrowClockwise,
          onPressed: () => setState(() {
            _replay++;
            _fish += 10;
          }),
        ),
        KeyedSubtree(
          key: ValueKey(_replay),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const MiroRise(child: Text('rise', style: MiroText.title)),
              const MiroPopIn(
                child: StreakCrystal(state: CrystalState.hero, size: 40),
              ),
              const MiroFloat(child: ChestIcon(width: 48)),
              const MiroPulse(child: StreakCrystal(size: 28)),
              Odometer(value: _fish, style: MiroText.h2),
            ],
          ),
        ),
      ],
    );
  }
}
