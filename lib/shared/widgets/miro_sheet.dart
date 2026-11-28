import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/miro_tokens.dart';
import 'miro_button.dart';
import 'miro_icon_button.dart';

/// Membuka bottom sheet MiRO (DESIGN_SYSTEM §7.9, HANDOFF 19). Sheet bukan
/// route (ARCHITECTURE §3); tombol kembali Android dan ketuk scrim
/// menutupnya. Tinggi maksimal 90% layar, isi bisa di-scroll
/// (RESPONSIVE §7).
Future<T?> showMiroSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: MiroColors.surface,
    barrierColor: MiroColors.scrim,
    elevation: 0,
    showDragHandle: false,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(MiroRadius.sheet),
      ),
    ),
    sheetAnimationStyle: const AnimationStyle(
      duration: MiroMotion.base,
      reverseDuration: MiroMotion.base,
      curve: MiroMotion.easeOut,
    ),
    builder: (_) => child,
  );
}

/// Isi standar sheet: handle 40×5, judul opsional + tombol tutup, isi yang
/// bisa di-scroll, dan [footer] yang tetap di bawah.
class MiroSheet extends StatelessWidget {
  const MiroSheet({
    super.key,
    required this.child,
    this.title,
    this.titleTrailing,
    this.footer,
    this.showClose = false,
    this.padding = const EdgeInsets.fromLTRB(
      MiroSpace.x5,
      0,
      MiroSpace.x5,
      MiroSpace.x6,
    ),
  });

  final Widget child;
  final String? title;

  /// Tautan di kanan judul (mis. "Kelola anak" di 19).
  final Widget? titleTrailing;
  final Widget? footer;
  final bool showClose;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: MiroColors.line,
                borderRadius: BorderRadius.circular(MiroRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: MiroSpace.x3),
          if (title != null || showClose)
            Padding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                0,
                padding.right,
                MiroSpace.x3,
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title!, style: MiroText.h3),
                      ),
                    ),
                  if (titleTrailing != null) titleTrailing!,
                  if (showClose)
                    MiroIconButton(
                      icon: PhosphorIcons.x(PhosphorIconsStyle.bold),
                      label: context.tr('common.close'),
                      size: 40,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                ],
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                0,
                padding.right,
                footer == null ? padding.bottom : MiroSpace.x3,
              ),
              child: child,
            ),
          ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                0,
                padding.right,
                padding.bottom,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// Sheet konfirmasi (33, 40): `role=alertdialog`, dua tombol sama tinggi.
/// Aksi aman ([safeLabel]) lebih lebar dan mendapat fokus awal; aksi bahaya
/// ([dangerLabel]) berupa tombol sekunder berteks merah.
class MiroAlertSheet extends StatelessWidget {
  const MiroAlertSheet({
    super.key,
    required this.title,
    required this.safeLabel,
    required this.dangerLabel,
    required this.onSafe,
    required this.onDanger,
    this.body,
    this.illustration,
    this.extra,
    this.safeVariant = MiroButtonVariant.success,
    this.dangerLoading = false,
  });

  final String title;
  final String? body;
  final Widget? illustration;

  /// Isi tambahan di bawah teks (mis. bar progres langkah di 33).
  final Widget? extra;
  final String safeLabel;
  final String dangerLabel;
  final VoidCallback onSafe;
  final VoidCallback? onDanger;
  final MiroButtonVariant safeVariant;
  final bool dangerLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: MiroSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) illustration!,
            const SizedBox(height: MiroSpace.x2),
            Text(title, style: MiroText.h2, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: MiroSpace.x2),
              Text(
                body!,
                style: MiroText.body,
                textAlign: TextAlign.center,
              ),
            ],
            if (extra != null) ...[
              const SizedBox(height: MiroSpace.x3),
              extra!,
            ],
            const SizedBox(height: MiroSpace.x4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 10,
                  child: _DangerOutline(
                    label: dangerLabel,
                    onPressed: onDanger,
                    loading: dangerLoading,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 14,
                  child: Focus(
                    autofocus: true,
                    child: MiroButton(
                      label: safeLabel,
                      onPressed: onSafe,
                      variant: safeVariant,
                      size: MiroButtonSize.m,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerOutline extends StatelessWidget {
  const _DangerOutline({
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    // Mockup 33: tombol sekunder putih, teks merah 700.
    return MiroButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      variant: MiroButtonVariant.dangerOutline,
      size: MiroButtonSize.m,
    );
  }
}
