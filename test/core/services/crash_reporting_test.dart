import 'package:flutter_test/flutter_test.dart';
import 'package:miro_app/core/services/crash_reporting.dart';

void main() {
  group('CrashReporting.scrubText (QA §2)', () {
    test('menghapus email', () {
      expect(
        CrashReporting.scrubText('gagal login bunda.dinda@gmail.com'),
        'gagal login [email]',
      );
    });

    test('menghapus URL dan path foto Storage', () {
      final out = CrashReporting.scrubText(
        'upload gagal https://abc.supabase.co/storage/v1/object/public/'
        'mission-assets/uid-1/foto_123.jpg',
      );
      expect(out, isNot(contains('foto_123')));
      expect(out, isNot(contains('uid-1')));
      expect(out, contains('[foto]'));
    });

    test('menghapus path foto lokal', () {
      final out = CrashReporting.scrubText(
        'tidak bisa baca /data/user/0/app/cache/IMG_2026.jpg',
      );
      expect(out, isNot(contains('IMG_2026')));
    });

    test('menghapus query string (filter REST berisi id)', () {
      expect(
        CrashReporting.scrubText('GET /rest/v1/children?id=eq.abc'),
        'GET /rest/v1/children?[query]',
      );
    });

    test('menghapus nama anak yang didaftarkan, utuh per kata', () {
      final out = CrashReporting.scrubText(
        'Rafi gagal disimpan, rafiq tetap',
        sensitive: {'Rafi'},
      );
      expect(out, '[nama] gagal disimpan, rafiq tetap');
    });

    test('teks tanpa data sensitif tidak berubah', () {
      expect(
        CrashReporting.scrubText('Null check operator used on a null value'),
        'Null check operator used on a null value',
      );
    });
  });
}
