// Gagal jika jumlah temuan `flutter analyze` melebihi baseline di
// docs/LINT_BASELINE.md, atau jika ada warning/error (DECISIONS §H12).
import 'dart:io';

Future<void> main() async {
  final doc = File('docs/LINT_BASELINE.md').readAsStringSync();
  final match = RegExp(r'^Batas: (\d+)$', multiLine: true).firstMatch(doc);
  if (match == null) {
    stderr.writeln('Baris "Batas: N" tidak ditemukan di docs/LINT_BASELINE.md');
    exit(2);
  }
  final limit = int.parse(match.group(1)!);

  final result = await Process.run(
    'flutter',
    ['analyze', '--no-fatal-infos', '--no-fatal-warnings'],
    runInShell: true,
  );
  final out = '${result.stdout}${result.stderr}';
  final lines = out.split('\n');
  final infos = lines.where((l) => l.trimLeft().startsWith('info ')).length;
  final warnings =
      lines.where((l) => l.trimLeft().startsWith('warning ')).length;
  final errors = lines.where((l) => l.trimLeft().startsWith('error ')).length;
  final total = infos + warnings + errors;

  stdout.writeln(
    'flutter analyze: $total temuan '
    '(info $infos, warning $warnings, error $errors); batas $limit',
  );
  if (errors > 0 || warnings > 0) {
    stdout.writeln(out);
    stderr.writeln('Ada warning/error. Perbaiki sebelum merge.');
    exit(1);
  }
  if (total > limit) {
    stdout.writeln(out);
    stderr.writeln('Temuan naik dari baseline ($total > $limit).');
    exit(1);
  }
  if (total < limit) {
    stdout.writeln(
      'Temuan turun. Perbarui "Batas: $total" di docs/LINT_BASELINE.md.',
    );
  }
}
