import 'package:flutter_test/flutter_test.dart';
import 'package:miro_app/core/app_info.dart';
import 'package:miro_app/core/l10n/strings_en.dart';
import 'package:miro_app/core/l10n/strings_id.dart';
import 'package:miro_app/core/l10n/tr.dart';

void main() {
  test('kamus ID dan EN punya kunci yang sama persis', () {
    expect(kStringsEn.keys.toSet(), kStringsId.keys.toSet());
  });

  test('tidak ada teks kosong', () {
    for (final map in [kStringsId, kStringsEn]) {
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });

  test('tidak ada pemisah AI slop (· atau —) di kamus', () {
    for (final map in [kStringsId, kStringsEn]) {
      for (final entry in map.entries) {
        expect(entry.value, isNot(contains('·')), reason: entry.key);
        expect(entry.value, isNot(contains('—')), reason: entry.key);
      }
    }
  });

  group('MiroStrings.lookup', () {
    test('memakai bahasa aktif', () {
      expect(MiroStrings.lookup('en', 'common.next'), 'NEXT');
      expect(MiroStrings.lookup('id', 'common.next'), 'LANJUT');
    });

    test('kunci yang tidak ada dikembalikan apa adanya', () {
      expect(MiroStrings.lookup('id', 'tidak.ada'), 'tidak.ada');
    });

    test('mengganti {mascot} dan argumen', () {
      // Kunci uji sementara tidak ada di kamus: lookup mengembalikan
      // kuncinya sendiri, lalu placeholder tetap diganti.
      expect(
        MiroStrings.lookup('id', 'Hai, aku {mascot}! {n} misi', args: {'n': 3}),
        'Hai, aku $kMascotName! 3 misi',
      );
    });
  });
}
