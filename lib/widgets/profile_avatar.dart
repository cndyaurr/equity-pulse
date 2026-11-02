
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  late Future<String> _initials;

  @override
  void initState() {
    super.initState();
    _initials = _loadInitials();
  }

  Future<String> _loadInitials() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('user_data');

    if (rawUser == null || rawUser.isEmpty) return '?';

    try {
      final user = jsonDecode(rawUser) as Map<String, dynamic>;
      final name = user['name']?.toString().trim() ?? '';

      if (name.isEmpty) return '?';

      final parts = name.split(RegExp(r'\s+'));

      if (parts.length == 1) {
        return parts.first[0].toUpperCase();
      }

      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } catch (_) {
      return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFFFE5CC),
      child: FutureBuilder<String>(
        future: _initials,
        builder: (context, snapshot) {
          return Text(
            snapshot.data ?? '?',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF58220),
            ),
          );
        },
      ),
    );
  }
}
