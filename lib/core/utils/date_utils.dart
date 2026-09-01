/// Parsing tanggal yang aman dari berbagai format yang dikirim Supabase.
///
/// Sebelumnya fungsi ini (byte demi byte identik) ditulis ulang terpisah di
/// `home_page.dart` dan `progress_page.dart`.
DateTime? parseDateSafely(String dateStr) {
  if (dateStr.isEmpty) return null;

  String s = dateStr.trim();

  // Normalize ke ISO8601
  if (!s.contains('T') && s.contains(' ')) {
    s = s.replaceFirst(' ', 'T');
  }

  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}
