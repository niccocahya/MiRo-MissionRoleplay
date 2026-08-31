import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mission_model.dart';
import 'role_model.dart';

// Provider ini akan menarik SELURUH data misi dari Supabase
final missionsProvider = FutureProvider<List<MissionModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('missions_master').select();
  return response.map((data) => MissionModel.fromJson(data)).toList();
});

// Provider untuk memfilter misi berdasarkan Role ID tertentu
// Cara pakainya nanti: ref.watch(missionsByRoleProvider('artist'))
final missionsByRoleProvider =
    FutureProvider.family<List<MissionModel>, String>((ref, roleId) async {
      final allMissions = await ref.watch(missionsProvider.future);
      return allMissions.where((mission) => mission.roleId == roleId).toList();
    });

// Provider untuk menarik data roles_master
final rolesProvider = FutureProvider<List<RoleModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('roles_master').select();
  return response.map((data) => RoleModel.fromJson(data)).toList();
});
