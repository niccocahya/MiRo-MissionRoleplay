import 'package:flutter/material.dart';

import 'miro_tokens.dart';

/// ThemeData MiRO v2, dibangun sepenuhnya dari token (`miro_tokens.dart`).
///
/// Layar lama yang masih memakai widget Material (ElevatedButton, TextField,
/// bottom sheet) ikut berganti ke Nunito dan warna baru lewat tema ini,
/// sampai layarnya di-redesign. Efek riak Material dimatikan karena umpan
/// balik tekan v2 memakai sistem lip (`MiroPressable`).
abstract final class MiroTheme {
  static ThemeData get light {
    final textTheme = TextTheme(
      displayLarge: MiroText.display,
      headlineLarge: MiroText.h1,
      headlineMedium: MiroText.h2,
      headlineSmall: MiroText.h3,
      titleLarge: MiroText.h3,
      titleMedium: MiroText.title,
      titleSmall: MiroText.bodyStrong,
      bodyLarge: MiroText.bodyLg,
      bodyMedium: MiroText.body,
      bodySmall: MiroText.caption,
      labelLarge: MiroText.button(size: 15),
      labelMedium: MiroText.label,
      labelSmall: MiroText.small,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(MiroRadius.md),
      borderSide: const BorderSide(color: MiroColors.line, width: 2),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: MiroText.family,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MiroColors.navy900,
        primary: MiroColors.navy900,
        onPrimary: MiroColors.white,
        secondary: MiroColors.actionPrimary,
        onSecondary: MiroColors.white,
        error: MiroColors.red600,
        surface: MiroColors.surface,
        onSurface: MiroColors.ink,
      ),
      scaffoldBackgroundColor: MiroColors.app,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: MiroColors.app,
        foregroundColor: MiroColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: MiroText.title,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MiroColors.actionPrimary,
          foregroundColor: MiroColors.white,
          elevation: 0,
          minimumSize: const Size(MiroSize.touch, MiroSize.buttonM),
          padding: const EdgeInsets.symmetric(horizontal: MiroSpace.x5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiroRadius.lg),
          ),
          textStyle: MiroText.button(size: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MiroColors.link,
          minimumSize: const Size(MiroSize.touch, MiroSize.touch),
          textStyle: MiroText.bodyStrong,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MiroColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MiroSpace.x4,
          vertical: MiroSpace.x4,
        ),
        hintStyle: MiroText.body.copyWith(color: MiroColors.ink3),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: MiroColors.navy900, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: MiroColors.red500, width: 2),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: MiroColors.red500, width: 2),
        ),
        errorStyle: MiroText.caption.copyWith(color: MiroColors.red700),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MiroColors.surface,
        modalBarrierColor: MiroColors.scrim,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MiroRadius.sheet),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: MiroColors.divider,
        thickness: 2,
        space: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MiroColors.navy900,
        contentTextStyle: MiroText.bodyStrong.copyWith(color: MiroColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MiroRadius.lg),
        ),
      ),
    );
  }
}
