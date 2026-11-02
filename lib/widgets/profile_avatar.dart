
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key});

  // Menyimpan inisial yang digunakan bersama oleh semua avatar.
  static final ValueNotifier<String> initials =
      ValueNotifier<String>('?');

  // Memuat inisial dari SharedPreferences.
  static Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('user_data');

    if (rawUser == null || rawUser.isEmpty) {
      initials.value = '?';
      return;
    }

    try {
      final user = jsonDecode(rawUser) as Map<String, dynamic>;

      updateInitials(user['name']?.toString() ?? '');
    } catch (_) {
      initials.value = '?';
    }
  }

  // Menghitung inisial berdasarkan nama.
  static void updateInitials(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      initials.value = '?';
      return;
    }

    final parts = trimmedName.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      initials.value = parts.first[0].toUpperCase();
    } else {
      initials.value =
          '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
  }

  // Menyimpan data pengguna dan langsung memperbarui avatar.
  static Future<void> updateUser(
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_data', jsonEncode(user));

    updateInitials(user['name']?.toString() ?? '');
  }

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  @override
  void initState() {
    super.initState();
    ProfileAvatar.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ProfileAvatar.initials,
      builder: (context, value, child) {
        return CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFFFE5CC),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF58220),
            ),
          ),
        );
      },
    );
  }
}
