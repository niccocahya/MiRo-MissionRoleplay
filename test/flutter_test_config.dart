import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/golden.dart';

/// Dijalankan sebelum setiap file tes: memuat font Nunito agar golden
/// test memakai font yang sama dengan aplikasi.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadMiroFonts();
  await testMain();
}
