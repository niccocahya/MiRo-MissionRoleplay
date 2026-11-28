import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Laporan crash lewat Sentry (docs/standards/QA.md §2).
///
/// Aturan yang dijaga di sini:
/// - DSN hanya dari `--dart-define` (`SENTRY_DSN`), tidak pernah di kode.
/// - DSN kosong atau build debug = Sentry tidak dinyalakan; app tetap jalan.
/// - `sendDefaultPii = false`, tanpa session replay dan tanpa screenshot.
/// - Nama anak, email, catatan refleksi, dan path foto dihapus dari event
///   dan breadcrumb sebelum dikirim ([scrubText]).
abstract final class CrashReporting {
  static const _dsn = String.fromEnvironment('SENTRY_DSN');

  /// Nama anak yang sedang dimuat app. Didaftarkan oleh provider anak agar
  /// bisa dihapus dari teks error (mis. pesan exception yang menyebut nama).
  static final Set<String> _sensitive = {};

  /// True jika Sentry aktif di sesi ini.
  static bool get enabled => _enabled;
  static bool _enabled = false;

  /// Menjalankan [appRunner] dengan Sentry jika DSN ada dan build release.
  /// Sentry memasang `FlutterError.onError` dan
  /// `PlatformDispatcher.instance.onError` sendiri; jika Sentry mati, kita
  /// tetap memasang keduanya agar error tidak hilang diam-diam.
  static Future<void> run(FutureOr<void> Function() appRunner) async {
    if (_dsn.isEmpty || !kReleaseMode) {
      _installFallbackHandlers();
      await appRunner();
      return;
    }
    _enabled = true;
    await SentryFlutter.init(_configure, appRunner: appRunner);
  }

  static void _configure(SentryFlutterOptions o) {
    o
      ..dsn = _dsn
      ..sendDefaultPii = false
      ..tracesSampleRate = 0.1
      ..attachScreenshot = false
      ..attachThreads = false
      ..beforeSend = _beforeSend
      ..beforeBreadcrumb = _beforeBreadcrumb;
    // JANGAN nyalakan session replay (`experimental.replay`) atau view
    // hierarchy: keduanya default mati dan bisa merekam wajah serta nama
    // anak (QA §2). Sengaja tidak disentuh di sini.
  }

  static void _installFallbackHandlers() {
    final flutterOriginal = FlutterError.onError;
    FlutterError.onError = (details) {
      flutterOriginal?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Error tak tertangani: ${scrubText('$error')}');
      return true; // Ditangani: jangan sampai app tertutup.
    };
  }

  /// Daftarkan nama anak (atau teks sensitif lain) supaya dihapus dari
  /// laporan. Teks pendek (< 2 huruf) diabaikan agar tidak menghapus
  /// potongan kata secara acak.
  static void registerSensitive(Iterable<String?> values) {
    for (final v in values) {
      final t = v?.trim() ?? '';
      if (t.length >= 2) _sensitive.add(t);
    }
  }

  /// Catat error yang sudah ditangani (mis. di `catch`) tanpa data anak.
  static Future<void> report(Object error, StackTrace? stack) async {
    if (!_enabled) {
      debugPrint('Error: ${scrubText('$error')}');
      return;
    }
    await Sentry.captureException(error, stackTrace: stack);
  }

  // ---------------------------------------------------------------------------
  // Scrubbing
  // ---------------------------------------------------------------------------

  static final _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');

  /// Path/URL foto di Storage (bucket lama maupun baru) dan file lokal.
  static final _photoPath = RegExp(
    r'''(https?://\S+/storage/v1/object/\S+|[\w./-]*\b(mission-assets|user_photo|memories)/[^\s'",)]+|[\w./\\:-]+\.(jpe?g|png|heic|webp))''',
    caseSensitive: false,
  );

  /// Query string di URL (REST Supabase membawa id dan filter di sini).
  static final _query = RegExp(r'\?[^\s#]*');

  /// Nama kunci data yang selalu dihapus isinya.
  static const _sensitiveKeys = {
    'nickname',
    'name',
    'full_name',
    'child_name',
    'note',
    'notes',
    'reflection',
    'email',
    'photo',
    'photo_url',
    'path',
    'url',
    'avatar_url',
  };

  /// Menghapus email, path foto, query string, dan nama yang didaftarkan
  /// dari [text]. Dipakai untuk pesan exception, breadcrumb, dan log.
  @visibleForTesting
  static String scrubText(String text, {Set<String>? sensitive}) {
    var out = text
        .replaceAll(_email, '[email]')
        .replaceAll(_photoPath, '[foto]')
        .replaceAll(_query, '?[query]');
    for (final name in sensitive ?? _sensitive) {
      out = out.replaceAll(
        RegExp('\\b${RegExp.escape(name)}\\b', caseSensitive: false),
        '[nama]',
      );
    }
    return out;
  }

  static Map<String, dynamic>? _scrubMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return data.map((key, value) {
      if (_sensitiveKeys.contains(key.toLowerCase())) {
        return MapEntry(key, '[dihapus]');
      }
      if (value is String) return MapEntry(key, scrubText(value));
      if (value is Map<String, dynamic>) return MapEntry(key, _scrubMap(value));
      return MapEntry(key, value);
    });
  }

  static FutureOr<SentryEvent?> _beforeSend(SentryEvent event, Hint hint) {
    final message = event.message;
    if (message != null) {
      event.message = SentryMessage(scrubText(message.formatted));
    }
    for (final e in event.exceptions ?? const <SentryException>[]) {
      final value = e.value;
      if (value != null) e.value = scrubText(value);
    }
    event.breadcrumbs = event.breadcrumbs
        ?.map((b) => _beforeBreadcrumb(b, Hint()))
        .whereType<Breadcrumb>()
        .toList();
    // ignore: deprecated_member_use
    event.extra = _scrubMap(event.extra);
    event.user = SentryUser(); // Tanpa id/email/IP pengguna.
    return event;
  }

  static Breadcrumb? _beforeBreadcrumb(Breadcrumb? crumb, Hint hint) {
    if (crumb == null) return null;
    final message = crumb.message;
    if (message != null) crumb.message = scrubText(message);
    crumb.data = _scrubMap(crumb.data);
    return crumb;
  }
}
