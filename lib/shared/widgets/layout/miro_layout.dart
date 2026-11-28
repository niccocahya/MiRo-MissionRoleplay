import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/theme/miro_tokens.dart';
import '../miro_icon_button.dart';
import '../miro_progress.dart';

/// Padding samping layar: 20, atau 16 di lebar < 360 (RESPONSIVE §2).
double screenGutter(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 360 ? MiroSpace.x4 : MiroSpace.x5;

/// Lebar konten maksimal di tablet (RESPONSIVE §8).
const kTabletMaxWidth = 480.0;

/// Membatasi lebar konten 480 di tengah saat lebar ≥ 600 (tablet).
class MiroMaxWidth extends StatelessWidget {
  const MiroMaxWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kTabletMaxWidth),
        child: child,
      ),
    );
  }
}

/// Kerangka layar standar (COMPONENTS §5.2): latar `app`, safe area,
/// [header] di atas, [body] yang bisa di-scroll, dan [footer] (biasanya
/// [MiroStickyFooter]) yang tetap terlihat dan naik di atas keyboard
/// (RESPONSIVE §3, §6).
class MiroScaffold extends StatelessWidget {
  const MiroScaffold({
    super.key,
    required this.body,
    this.header,
    this.footer,
    this.background = MiroColors.app,
    this.backgroundDecoration,
    this.scrollable = true,
    this.bodyPadding,
  });

  final Widget body;
  final Widget? header;
  final Widget? footer;
  final Color background;

  /// Latar khusus (mis. gradien suasana) di belakang seluruh layar.
  final Widget? backgroundDecoration;

  /// `false` jika [body] sudah mengatur scroll sendiri (mis. `ListView`).
  final bool scrollable;
  final EdgeInsetsGeometry? bodyPadding;

  @override
  Widget build(BuildContext context) {
    final gutter = screenGutter(context);
    final padding = bodyPadding ?? EdgeInsets.symmetric(horizontal: gutter);
    final content = scrollable
        ? SingleChildScrollView(
            padding: padding,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: body,
          )
        : Padding(padding: padding, child: body);

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (backgroundDecoration != null)
            Positioned.fill(child: backgroundDecoration!),
          SafeArea(
            bottom: footer == null,
            child: MiroMaxWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (header != null) header!,
                  Expanded(child: content),
                  if (footer != null) footer!,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Area tombol utama di bawah layar (COMPONENTS §5.2): padding 16/20/24 +
/// safe area bawah sistem. [secondary] (tautan) opsional di bawah tombol.
class MiroStickyFooter extends StatelessWidget {
  const MiroStickyFooter({
    super.key,
    required this.primary,
    this.secondary,
    this.above,
  });

  final Widget primary;
  final Widget? secondary;

  /// Isi kecil di atas tombol (mis. catatan tagihan di 38).
  final Widget? above;

  @override
  Widget build(BuildContext context) {
    final gutter = screenGutter(context);
    final systemBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        MiroSpace.x4,
        gutter,
        MiroSpace.x6 + systemBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (above != null) ...[above!, const SizedBox(height: MiroSpace.x3)],
          primary,
          if (secondary != null) ...[
            const SizedBox(height: MiroSpace.x2),
            Center(child: secondary!),
          ],
        ],
      ),
    );
  }
}

/// Header layar detail (COMPONENTS §5.2): tombol kembali 44 + judul 17/900
/// + slot kanan. Tinggi 64 (DECISIONS A4).
class MiroPageHeader extends StatelessWidget {
  const MiroPageHeader({
    super.key,
    this.title,
    this.onBack,
    this.trailing,
    this.onMood = false,
    this.center,
  });

  final String? title;

  /// Default: `Navigator.maybePop`.
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool onMood;

  /// Pengganti judul (mis. `SegmentBar` di onboarding).
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final gutter = screenGutter(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: MiroSize.topBar),
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, MiroSpace.x2, gutter, 0),
        child: Row(
          children: [
            MiroIconButton(
              icon: PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
              label: context.tr('common.back'),
              variant: onMood
                  ? MiroIconButtonVariant.onMood
                  : MiroIconButtonVariant.surface,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: MiroSpace.x3),
            Expanded(
              child: center ??
                  (title == null
                      ? const SizedBox.shrink()
                      : Semantics(
                          header: true,
                          child: Text(title!, style: MiroText.title),
                        )),
            ),
            if (trailing != null) ...[
              const SizedBox(width: MiroSpace.x3),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Kerangka onboarding (COMPONENTS §5.2; 01, 15 sampai 17, 23 sampai 29):
/// latar gradien suasana + salju 50%, tombol kembali, dan `SegmentBar`
/// langkah [step] dari [steps].
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.body,
    required this.step,
    required this.steps,
    this.footer,
    this.onBack,
    this.showBack = true,
  });

  final Widget body;
  final int step;
  final int steps;
  final Widget? footer;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final bar = SegmentBar(
      current: step,
      steps: steps,
      onMood: true,
      semanticsLabel: context.tr(
        'onboarding.stepOf',
        args: {'n': step, 'total': steps},
      ),
    );
    return MiroScaffold(
      background: MiroColors.sky300,
      backgroundDecoration: const MoodBackground(),
      header: showBack
          ? MiroPageHeader(onMood: true, onBack: onBack, center: bar)
          : Padding(
              padding: EdgeInsets.fromLTRB(
                screenGutter(context),
                MiroSpace.x6,
                screenGutter(context),
                0,
              ),
              child: bar,
            ),
      body: body,
      footer: footer,
    );
  }
}

/// Latar suasana (DESIGN_SYSTEM §1.3 `bg-mood`): gradien sky → sand +
/// overlay salju 50%. Dipakai onboarding dan layar perayaan.
class MoodBackground extends StatelessWidget {
  const MoodBackground({super.key, this.navy = false});

  /// Varian navy (Lencana baru 31, Streak terhenti 45).
  final bool navy;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: navy
              ? const BoxDecoration(color: MiroColors.navy900)
              : const BoxDecoration(gradient: MiroColors.moodGradient),
        ),
        Opacity(
          opacity: navy ? 0.25 : 0.5,
          child: Image.asset(
            'assets/mascot/snow.webp',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
      ],
    );
  }
}

/// Judul besar + paragraf + maskot di kanan (COMPONENTS §5.2;
/// 07, 41, 43, 50, 51, 53).
class ScreenHero extends StatelessWidget {
  const ScreenHero({
    super.key,
    required this.title,
    this.body,
    this.illustration,
  });

  final String title;
  final String? body;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: MiroText.h2),
                ),
                if (body != null) ...[
                  const SizedBox(height: 6),
                  Text(body!, style: MiroText.body),
                ],
              ],
            ),
          ),
        ),
        if (illustration != null) ...[
          const SizedBox(width: 10),
          illustration!,
        ],
      ],
    );
  }
}
