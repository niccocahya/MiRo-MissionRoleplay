import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Satu akun orang tua yang PERNAH login di device ini -- cuma nyimpen
/// email + nama tampilan, TIDAK PERNAH nyimpen password/token, jadi ini
/// aman disimpan di SharedPreferences biasa (bukan secure storage).
class RecentAccount {
  const RecentAccount({required this.email, required this.displayName});

  final String email;
  final String displayName;

  Map<String, String> toJson() => {'email': email, 'name': displayName};

  factory RecentAccount.fromJson(Map<String, dynamic> json) => RecentAccount(
        email: json['email'] as String? ?? '',
        displayName: json['name'] as String? ?? '',
      );
}

/// Dulu tiap kali mau gonta-ganti akun (mis. 2 orang tua gantian pakai HP
/// yang sama buat 2 anak beda parent_id), harus ngetik ulang email dari
/// nol tiap kali. Ini nyimpen daftar akun yang PERNAH sukses login/daftar
/// di device ini (max 3, terbaru duluan) buat quick-pick di layar Login --
/// password tetep harus diketik ulang (kita nggak nyimpen sesi kedua
/// secara paralel, cuma mempercepat isi email-nya).
class RecentAccountsNotifier extends Notifier<List<RecentAccount>> {
  static const _key = 'recent_accounts';
  static const _maxAccounts = 3;

  @override
  List<RecentAccount> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      state = decoded
          .map((e) => RecentAccount.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      // Data lama korup/format berubah -- nggak fatal, mulai dari kosong lagi.
    }
  }

  Future<void> remember(String email, String displayName) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) return;

    final next = [
      RecentAccount(email: trimmedEmail, displayName: displayName.trim()),
      ...state.where((a) => a.email.toLowerCase() != trimmedEmail),
    ].take(_maxAccounts).toList();

    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(next.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> forget(String email) async {
    final next =
        state.where((a) => a.email.toLowerCase() != email.toLowerCase()).toList();
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(next.map((a) => a.toJson()).toList()),
    );
  }
}

final recentAccountsProvider =
    NotifierProvider<RecentAccountsNotifier, List<RecentAccount>>(
  () => RecentAccountsNotifier(),
);
