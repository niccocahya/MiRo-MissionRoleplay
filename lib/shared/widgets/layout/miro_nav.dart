import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/theme/miro_tokens.dart';
import '../../icons/game_icons.dart';
import '../miro_icon_button.dart';
import '../miro_pressable.dart';
import '../motion/miro_motion.dart';
import 'miro_layout.dart';

/// Top bar tab utama (DESIGN_SYSTEM §7.10, HANDOFF 02): kiri switcher
/// anak/kelas (avatar 34 + nama + chevron), kanan jumlah ikan, tombol cari
/// opsional, dan lonceng notifikasi 40. Tinggi 64.
class MiroTopBar extends StatelessWidget {
  const MiroTopBar({
    super.key,
    required this.profileName,
    required this.profileAvatar,
    required this.fish,
    required this.onSwitchProfile,
    required this.onNotifications,
    this.hasUnread = false,
    this.onSearch,
  });

  final String profileName;
  final Widget profileAvatar;
  final int fish;
  final VoidCallback onSwitchProfile;
  final VoidCallback onNotifications;
  final bool hasUnread;

  /// Ikon cari misi (DECISIONS B9). `null` = disembunyikan.
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final gutter = screenGutter(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: MiroSize.topBar),
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, MiroSpace.x2, gutter, 0),
        child: Row(
          children: [
            Flexible(
              child: MiroPressable(
                onTap: onSwitchProfile,
                semanticsLabel: context.tr(
                  'topbar.switchProfile',
                  args: {'name': profileName},
                ),
                excludeChildSemantics: true,
                color: MiroColors.surface,
                lipColor: MiroColors.line,
                lip: MiroLip.iconButton,
                radius: MiroRadius.pill,
                border: Border.all(color: MiroColors.line, width: 2),
                padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(dimension: 34, child: profileAvatar),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        profileName,
                        style: MiroText.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: MiroSpace.x1),
                    Icon(
                      PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                      size: 16,
                      color: MiroColors.ink,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: MiroSpace.x3),
            Semantics(
              label: context.tr('topbar.fish', args: {'n': fish}),
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FishIcon(size: 24),
                  const SizedBox(width: MiroSpace.x1),
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.5,
                    child: Odometer(
                      value: fish,
                      style: MiroText.title.copyWith(
                        color: MiroColors.amber800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onSearch != null) ...[
              const SizedBox(width: 10),
              MiroIconButton(
                icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                label: context.tr('topbar.search'),
                size: 40,
                onPressed: onSearch,
              ),
            ],
            const SizedBox(width: 10),
            MiroIconButton(
              icon: PhosphorIcons.bell(PhosphorIconsStyle.bold),
              label: context.tr('topbar.notifications'),
              size: 40,
              badge: hasUnread,
              onPressed: onNotifications,
            ),
          ],
        ),
      ),
    );
  }
}

/// Item navigasi bawah.
class MiroNavItem {
  const MiroNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Navigasi bawah 4 tab (DESIGN_SYSTEM §7.11, DECISIONS A4/B2): tinggi 80
/// + safe area, putih, border atas 2 `navy100`, ikon tanpa label. Tab aktif
/// ditandai wadah coral muda 56×44 yang bergeser ke tab baru (M14). Tab
/// terakhir (Profil) menampilkan [profileAvatar].
class MiroBottomNav extends StatelessWidget {
  const MiroBottomNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.profileAvatar,
  });

  final int index;
  final ValueChanged<int> onTap;

  /// Avatar akun (inisial) untuk tab Profil.
  final Widget Function(bool active) profileAvatar;

  static List<MiroNavItem> items(BuildContext context) => [
        MiroNavItem(
          label: context.tr('nav.adventure'),
          icon: PhosphorIcons.mapTrifold(PhosphorIconsStyle.bold),
          activeIcon: PhosphorIcons.mapTrifold(PhosphorIconsStyle.fill),
        ),
        MiroNavItem(
          label: context.tr('nav.challenges'),
          icon: PhosphorIcons.target(PhosphorIconsStyle.bold),
          activeIcon: PhosphorIcons.target(PhosphorIconsStyle.fill),
        ),
        MiroNavItem(
          label: context.tr('nav.memories'),
          icon: PhosphorIcons.images(PhosphorIconsStyle.bold),
          activeIcon: PhosphorIcons.images(PhosphorIconsStyle.fill),
        ),
        MiroNavItem(
          label: context.tr('nav.profile'),
          icon: PhosphorIcons.user(PhosphorIconsStyle.bold),
          activeIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final list = items(context);
    final systemBottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: MiroColors.surface,
        border: Border(top: BorderSide(color: MiroColors.navy100, width: 2)),
      ),
      padding:
          EdgeInsets.fromLTRB(MiroSpace.x3, 0, MiroSpace.x3, 6 + systemBottom),
      child: SizedBox(
        height: MiroSize.bottomNav - 8,
        child: Row(
          children: [
            for (var i = 0; i < list.length; i++)
              Expanded(
                child: _NavButton(
                  item: list[i],
                  active: i == index,
                  onTap: () => onTap(i),
                  child:
                      i == list.length - 1 ? profileAvatar(i == index) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
    this.child,
  });

  final MiroNavItem item;
  final bool active;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: MiroMotion.fast,
              width: 56,
              height: MiroSize.touch,
              decoration: BoxDecoration(
                color: active ? MiroColors.coral100 : null,
                borderRadius: BorderRadius.circular(MiroRadius.segmented),
                border: Border.all(
                  color: active ? MiroColors.coral200 : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: child ??
                    Icon(
                      active ? item.activeIcon : item.icon,
                      size: 28,
                      color: active ? MiroColors.coral500 : MiroColors.navy300,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Layout layar perayaan (COMPONENTS §5.2; 05, 21, 31, 45): latar penuh
/// (suasana atau navy), visual di tengah yang mengecil di layar pendek
/// (RESPONSIVE §3), judul, isi, dan CTA di bawah. Ketuk di mana saja
/// melompat ke keadaan akhir lewat [onSkip].
class CelebrationLayout extends StatelessWidget {
  const CelebrationLayout({
    super.key,
    required this.visual,
    required this.title,
    required this.footer,
    this.subtitle,
    this.content,
    this.navy = false,
    this.onSkip,
  });

  final Widget visual;
  final String title;
  final String? subtitle;
  final Widget? content;
  final Widget footer;
  final bool navy;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final titleColor = navy ? MiroColors.white : MiroColors.ink;
    final subColor = navy ? MiroColors.sky300 : MiroColors.navy700;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onSkip,
      child: MiroScaffold(
        background: navy ? MiroColors.navy900 : MiroColors.sky300,
        backgroundDecoration: MoodBackground(navy: navy),
        body: Builder(
          builder: (context) => Column(
            children: [
              // Layar pendek: jarak atas dikecilkan (RESPONSIVE §3).
              SizedBox(
                height: MediaQuery.sizeOf(context).height < 700
                    ? MiroSpace.x2
                    : MiroSpace.x6,
              ),
              Center(child: visual),
              const SizedBox(height: MiroSpace.x3),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  style: MiroText.display.copyWith(color: titleColor),
                  textAlign: TextAlign.center,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: MiroText.bodyLg.copyWith(color: subColor),
                  textAlign: TextAlign.center,
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: MiroSpace.x5),
                content!,
              ],
              const SizedBox(height: MiroSpace.x4),
            ],
          ),
        ),
        footer: footer,
      ),
    );
  }
}
