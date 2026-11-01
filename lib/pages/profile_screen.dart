import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color orange = Color(0xFFF58220);
  static const Color orangeDark = Color(0xFFD96812);
  static const Color pageBackground = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF737373);

  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController unit;
  bool isLoadingProfile = true;
  bool isSavingProfile = false;

  Future<bool> _updateProfile({
    required String newName,
    required String newUnit,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token login tidak ditemukan.');
      }

      final response = await http
          .put(
            Uri.parse('${ApiService.baseUrl}/profile'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'name': newName, 'work_location': newUnit}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true &&
          data['user'] is Map) {
        final updatedUser = Map<String, dynamic>.from(data['user'] as Map);

        if (!mounted) return false;

        setState(() {
          name.text = updatedUser['name']?.toString() ?? '';
          email.text = updatedUser['email']?.toString() ?? '';
          unit.text = updatedUser['work_location']?.toString() ?? '';
        });

        return true;
      }

      if (response.statusCode == 401) {
        throw Exception('Sesi login kedaluwarsa. Silakan login kembali.');
      }

      throw Exception(
        data is Map
            ? data['message']?.toString() ?? 'Gagal memperbarui profil.'
            : 'Respons server tidak valid.',
      );
    } catch (e) {
      debugPrint('Update profile error: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
      }

      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    final user = widget.user;

    name = TextEditingController(text: user?['name']?.toString() ?? '');

    email = TextEditingController(text: user?['email']?.toString() ?? '');

    unit = TextEditingController(
      text: user?['work_location']?.toString() ?? '',
    );

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/profile'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true &&
          data['user'] is Map) {
        final user = Map<String, dynamic>.from(data['user'] as Map);

        if (!mounted) return;

        setState(() {
          name.text = user['name']?.toString() ?? '';
          email.text = user['email']?.toString() ?? '';
          unit.text = user['work_location']?.toString() ?? '';
        });
      } else if (response.statusCode == 401) {
        throw Exception('Sesi login kedaluwarsa. Silakan login kembali.');
      } else {
        throw Exception(
          data is Map
              ? data['message']?.toString() ?? 'Gagal mengambil profil.'
              : 'Respons server tidak valid.',
        );
      }
    } catch (e) {
      debugPrint('Load profile error: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat profil: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingProfile = false);
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: pageBackground,
        appBar: AppBar(
          backgroundColor: pageBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Profil',
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            if (isLoadingProfile)
              const LinearProgressIndicator(color: orange, minHeight: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _profileHeader(),
                  const SizedBox(height: 28),

                  _section(
                    title: 'Informasi Pribadi',
                    children: [
                      _infoRow(
                        icon: Icons.badge_outlined,
                        title: 'Nama lengkap',
                        value: name.text,
                      ),
                      _infoRow(
                        icon: Icons.mail_outline_rounded,
                        title: 'Email perusahaan',
                        value: email.text,
                        trailing: const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF16845B),
                          size: 19,
                        ),
                      ),
                      _infoRow(
                        icon: Icons.business_outlined,
                        title: 'Unit kantor',
                        value: unit.text,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _section(
                    title: 'Kredensial & Otentikasi',
                    children: [
                      _actionRow(
                        icon: Icons.lock_outline_rounded,
                        title: 'Perbarui kata sandi',
                        subtitle: 'Ubah kata sandi akun Anda',
                        onTap: _showPasswordDialog,
                      ),
                      _actionRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi',
                        subtitle:
                            'Atur notifikasi keamanan dan informasi pasar',
                        trailing: Switch(
                          value: notificationsEnabled,
                          activeThumbColor: orange,
                          onChanged: (value) {
                            setState(() {
                              notificationsEnabled = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _section(
                    title: 'Pengaturan',
                    children: [
                      _actionRow(
                        icon: Icons.palette_outlined,
                        title: 'Tema aplikasi',
                        subtitle: 'Terang',
                        trailing: const Text(
                          'Terang',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _actionRow(
                        icon: Icons.support_agent_rounded,
                        title: 'Hubungi dukungan',
                        subtitle: 'Bantuan untuk akun EWF Gold Hub',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur dukungan belum dihubungkan.',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('auth_token');

                      if (!context.mounted) return;

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: const Text('Keluar dari akun'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD64545),
                      side: const BorderSide(color: Color(0xFFF0B8B8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Center(
                    child: Text(
                      'PT EQUITYWORLD FUTURES • EWF GOLD HUB',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool notificationsEnabled = true;

  Widget _profileHeader() => Column(
    children: [
      const SizedBox(height: 8),
      Container(
        width: 112,
        height: 112,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFE5CC),
        ),
        child: const Icon(Icons.person_rounded, size: 66, color: orange),
      ),
      const SizedBox(height: 14),
      Text(
        name.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 23,
          height: 1.2,
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        email.text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: textSecondary),
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: _showEditProfileDialog,
        style: OutlinedButton.styleFrom(
          foregroundColor: orangeDark,
          side: const BorderSide(color: orange, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          shape: const StadiumBorder(),
        ),
        child: const Text(
          'Edit profil',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _section({required String title, required List<Widget> children}) =>
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Icon(icon, color: textPrimary, size: 22),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) => ListTile(
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: textPrimary, size: 23),
    title: Text(
      title,
      style: const TextStyle(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: textSecondary, fontSize: 11),
    ),
    trailing:
        trailing ??
        const Icon(Icons.chevron_right_rounded, color: textSecondary),
  );

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: name.text);
    final unitController = TextEditingController(text: unit.text);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profil'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama lengkap'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unit kantor'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Unit kantor wajib diisi'
                      : null,
                ),
                TextFormField(
                  initialValue: email.text,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email perusahaan (terverifikasi)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: orange),
            onPressed: isSavingProfile
                ? null
                : () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    setState(() => isSavingProfile = true);

                    final success = await _updateProfile(
                      newName: nameController.text.trim(),
                      newUnit: unitController.text.trim(),
                    );

                    if (!mounted) return;

                    setState(() => isSavingProfile = false);

                    if (success) {
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil berhasil diperbarui.'),
                        ),
                      );
                    }
                  },
            child: isSavingProfile
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );

    nameController.dispose();
    unitController.dispose();
  }

  Future<void> _showPasswordDialog() async {
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Perbarui kata sandi'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata sandi saat ini',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  controller: newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata sandi baru',
                  ),
                  validator: (value) => value == null || value.length < 8
                      ? 'Minimal 8 karakter'
                      : null,
                ),
                TextFormField(
                  controller: confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi kata sandi baru',
                  ),
                  validator: (value) => value != newPassword.text
                      ? 'Kata sandi belum cocok'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: orange),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Validasi berhasil. Hubungkan endpoint API untuk memperbarui kata sandi.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
  }
}
