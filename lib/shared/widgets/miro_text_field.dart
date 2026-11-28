import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/miro_tokens.dart';
import 'motion/miro_motion.dart';

/// Field teks (DESIGN_SYSTEM §7.5, HANDOFF 15): label di atas dengan ikon
/// 16, tinggi 52, radius 12, border 2. Fokus: border navy + ring sky.
/// [error] memberi border merah, pesan dengan ikon di bawah, dan goyang
/// sekali (M4). [obscure] menambah tombol mata 44px yang berfungsi.
class MiroTextField extends StatefulWidget {
  const MiroTextField({
    super.key,
    required this.label,
    this.controller,
    this.icon,
    this.hint,
    this.helper,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final IconData? icon;
  final String? hint;

  /// Keterangan kecil di bawah field saat tidak ada error.
  final String? helper;

  /// Pesan error; `null` = tidak ada error.
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<MiroTextField> createState() => _MiroTextFieldState();
}

class _MiroTextFieldState extends State<MiroTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _hidden = true;
  bool _focused = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    setState(() => _focused = _focus.hasFocus);
    // UX_COMFORT §3: field aktif tidak boleh tertutup keyboard.
    if (_focus.hasFocus) {
      Future.delayed(MiroMotion.slow, () {
        if (!mounted || !_focus.hasFocus) return;
        Scrollable.maybeOf(context)?.position.ensureVisible(
              context.findRenderObject()!,
              alignment: 0.5,
              duration: MiroMotion.base,
            );
      });
    }
  }

  @override
  void didUpdateWidget(covariant MiroTextField old) {
    super.didUpdateWidget(old);
    // Goyang sekali saat error baru muncul atau berganti.
    if (widget.error != null && widget.error != old.error) _shake++;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final borderColor = hasError
        ? MiroColors.red500
        : _focused
            ? MiroColors.navy900
            : MiroColors.line;

    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      obscureText: widget.obscure && _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      maxLength: widget.maxLength,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      minLines: 1,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      style: MiroText.bodyStrong.copyWith(
        fontWeight: FontWeight.w700,
        color: MiroColors.ink,
      ),
      cursorColor: MiroColors.navy900,
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        hintText: widget.hint,
        hintStyle: MiroText.bodyStrong.copyWith(
          fontWeight: FontWeight.w700,
          color: MiroColors.ink3,
        ),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );

    final box = AnimatedContainer(
      duration: MiroMotion.fast,
      constraints: const BoxConstraints(minHeight: MiroSize.input),
      padding: EdgeInsets.only(
        left: MiroSpace.x4,
        right: widget.obscure ? MiroSpace.x1 : MiroSpace.x4,
      ),
      decoration: BoxDecoration(
        color: widget.enabled ? MiroColors.surface : MiroColors.surfaceMuted,
        borderRadius: BorderRadius.circular(MiroRadius.md),
        border: Border.all(color: borderColor, width: 2),
        // Ring fokus 4px sky100 (DESIGN_SYSTEM §7.5).
        boxShadow: _focused && !hasError
            ? const [
                BoxShadow(color: MiroColors.sky100, spreadRadius: 4),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(child: field),
          if (widget.obscure)
            Semantics(
              // Node sendiri agar TalkBack bisa memfokuskan tombol mata.
              container: true,
              button: true,
              label: context.tr(
                _hidden ? 'field.showPassword' : 'field.hidePassword',
              ),
              excludeSemantics: true,
              child: InkResponse(
                onTap: () => setState(() => _hidden = !_hidden),
                radius: MiroSize.touch / 2,
                child: SizedBox.square(
                  dimension: MiroSize.touch,
                  child: Icon(
                    _hidden
                        ? PhosphorIcons.eye(PhosphorIconsStyle.bold)
                        : PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                    size: 22,
                    color: MiroColors.ink2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 16, color: MiroColors.ink2),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                widget.label,
                style: MiroText.label.copyWith(color: MiroColors.ink2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        MiroShake(
          signal: _shake,
          child: Semantics(
            container: true,
            label: widget.label,
            hint: widget.error ?? widget.helper,
            child: box,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          MiroRise(
            key: ValueKey(widget.error),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                    size: 16,
                    color: MiroColors.red700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.error!,
                      style: MiroText.label.copyWith(color: MiroColors.red700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(widget.helper!, style: MiroText.small),
        ],
      ],
    );
  }
}
