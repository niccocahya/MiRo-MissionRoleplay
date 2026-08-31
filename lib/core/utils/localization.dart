import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

// Helper sederhana untuk akses teks
String t(WidgetRef ref, String idText, String enText) {
  final lang = ref.watch(languageProvider);
  return lang == 'id' ? idText : enText;
}
