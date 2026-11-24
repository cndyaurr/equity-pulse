import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/profile_avatar.dart';
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
late final TextEditingController phone;
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

        // Simpan profil terbaru dan perbarui inisial avatar di seluruh halaman.
        await ProfileAvatar.updateUser(updatedUser);

        if (!mounted) return false;

        setState(() {
  name.text = updatedUser['name']?.toString() ?? '';
  phone.text = updatedUser['phone']?.toString() ?? '';
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
phone = TextEditingController(
  text: user?['phone']?.toString() ?? '',
);
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

        // Sinkronkan data dari server agar avatar selalu memakai nama terbaru.
        await ProfileAvatar.updateUser(user);

        if (!mounted) return;

      setState(() {
  name.text = user['name']?.toString() ?? '';
  phone.text = user['phone']?.toString() ?? '';
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
  phone.dispose();
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
  icon: Icons.phone_android_outlined,
  title: 'Nomor telepon',
  value: phone.text.isEmpty ? '-' : phone.text,
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
      
  icon: Icons.support_agent_rounded,
  title: 'Hubungi dukungan',
  subtitle: 'Email atau telepon tim dukungan EQUICKLY',
  onTap: _showSupportOptions,
),
                    ],
                  ),

                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();

                      final authToken = prefs.getString('auth_token');

                      // Hapus FCM token dari Laravel sebelum logout.
                      if (authToken != null && authToken.isNotEmpty) {
                        try {
                          final fcmToken =
                              await NotificationService.getDeviceToken();

                          if (fcmToken != null && fcmToken.isNotEmpty) {
                            await ApiService.removeDeviceToken(
                              authToken: authToken,
                              fcmToken: fcmToken,
                            );
                          }
                        } catch (e) {
                          debugPrint('Gagal menghapus FCM token: $e');
                        }
                      }

                      // Tetap lanjutkan logout meskipun penghapusan FCM gagal.
                      await prefs.remove('auth_token');
await prefs.remove('user_data');
await prefs.remove('remember_session');

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
                      'PT EQUITYWORLD FUTURES',
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
        ?trailing,
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


Future<void> _showSupportOptions() async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hubungi dukungan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih cara menghubungi tim dukungan EQUICKLY.',
                style: TextStyle(color: textSecondary),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE5CC),
                  child: Icon(Icons.email_outlined, color: orange),
                ),
                title: const Text('Email'),
                subtitle: const Text(
                  'itsupport.equicklye@gmail.com',
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  final uri = Uri(
                    scheme: 'mailto',
                    path: 'itsupport.equicklye@gmail.com',
                    queryParameters: {
                      'subject': 'Permintaan Bantuan EQUICKLY',
                    },
                  );

                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!opened && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tidak dapat membuka aplikasi email.'),
                      ),
                    );
                  }
                },
              ),

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE5CC),
                  child: Icon(Icons.phone_outlined, color: orange),
                ),
                title: const Text('Telepon'),
                subtitle: const Text('+62 857-4996-3720'),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  final uri = Uri(
                    scheme: 'tel',
                    path: '+6285749963720',
                  );

                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!opened && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tidak dapat membuka aplikasi telepon.'),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}


  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: name.text);
    final unitController = TextEditingController(text: unit.text);
    final formKey = GlobalKey<FormState>();

    try {
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
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                    ),
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

                      if (!mounted || !dialogContext.mounted) return;

                      if (success) {
                        Navigator.pop(dialogContext);

                        if (!mounted) return;

                        setState(() {
                          isSavingProfile = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Profil berhasil diperbarui.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: orange,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } else {
                        setState(() {
                          isSavingProfile = false;
                        });
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

      // Tunggu animasi penutupan dialog selesai sebelum dispose.
      await Future.delayed(const Duration(milliseconds: 300));
    } finally {
      nameController.dispose();
      unitController.dispose();
    }
  }


Future<void> _showPasswordDialog() async {
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final messenger = ScaffoldMessenger.of(context);

  final otpFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();
  int step = 0;
  bool isLoading = false;
  String verificationToken = '';

  String maskEmail(String value) {
    final parts = value.split('@');
    if (parts.length != 2) return value;

    final username = parts[0];
    final visible = username.length <= 2
        ? username[0]
        : username.substring(0, 2);

    return '$visible${'*' * (username.length - visible.length)}@${parts[1]}';
  }

  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendOtp() async {
              if (email.text.trim().isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Email akun tidak ditemukan.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setDialogState(() => isLoading = true);

              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');

                if (token == null || token.isEmpty) {
                  throw Exception('Sesi login tidak ditemukan.');
                }

                final result = await ApiService.requestPasswordOtp(
                  token: token,
                  method: 'email',
                );

                if (!dialogContext.mounted) return;

                if (result['success'] == true) {
                  setDialogState(() {
                    step = 1;
                    isLoading = false;
                  });
                } else {
                  setDialogState(() => isLoading = false);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Gagal mengirim OTP.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() => isLoading = false);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengirim OTP: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            Future<void> verifyOtp() async {
              if (!(otpFormKey.currentState?.validate() ?? false)) {
                return;
              }

              setDialogState(() => isLoading = true);

              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');

                if (token == null || token.isEmpty) {
                  throw Exception('Sesi login tidak ditemukan.');
                }

                final result = await ApiService.verifyPasswordOtp(
                  token: token,
                  method: 'email',
                  otp: otpController.text.trim(),
                );

                if (!dialogContext.mounted) return;

                if (result['success'] == true &&
                    result['verification_token'] != null) {
                  setDialogState(() {
                    verificationToken =
                        result['verification_token'].toString();
                    step = 2;
                    isLoading = false;
                  });
                } else {
                  setDialogState(() => isLoading = false);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'OTP tidak valid.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() => isLoading = false);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Verifikasi OTP gagal: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            Future<void> savePassword() async {
              if (!(passwordFormKey.currentState?.validate() ?? false)) {
                return;
              }

              setDialogState(() => isLoading = true);

              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');

                if (token == null || token.isEmpty) {
                  throw Exception('Sesi login tidak ditemukan.');
                }

                final result = await ApiService.confirmPasswordChange(
                  token: token,
                  verificationToken: verificationToken,
                  newPassword: newPasswordController.text,
                  confirmPassword: confirmPasswordController.text,
                  method: 'email',
                );

                if (!dialogContext.mounted) return;

                if (result['success'] == true) {
                  Navigator.pop(dialogContext);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ??
                            'Kata sandi berhasil diperbarui.',
                      ),
                      backgroundColor: orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  setDialogState(() => isLoading = false);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ??
                            'Gagal memperbarui kata sandi.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() => isLoading = false);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal memperbarui kata sandi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return PopScope(
              canPop: !isLoading,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  step == 0
                      ? 'Verifikasi Identitas'
                      : step == 1
                          ? 'Verifikasi Kode OTP'
                          : 'Perbarui Kata Sandi',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 360,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (step == 0) ...[
                          const Icon(
                            Icons.mark_email_read_outlined,
                            color: orange,
                            size: 55,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Untuk keamanan akun, kami akan mengirimkan '
                            'kode OTP ke email yang terdaftar.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Email tujuan',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  maskEmail(email.text.trim()),
                                  style: const TextStyle(
                                    color: orangeDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (step == 1) ...[
                          const Icon(
                            Icons.mark_email_read_outlined,
                            color: orange,
                            size: 50,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Masukkan kode OTP 6 digit yang telah dikirim '
                            'ke email Anda.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          Form(
                            key: otpFormKey,
                            child: TextFormField(
                              controller: otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Kode OTP',
                                hintText: '000000',
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: orange,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    !RegExp(r'^\d{6}$').hasMatch(value)) {
                                  return 'Masukkan OTP 6 digit.';
                                }
                                return null;
                              },
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    otpController.clear();
                                    setDialogState(() => step = 0);
                                  },
                            child: const Text(
                              'Kembali',
                              style: TextStyle(color: orange),
                            ),
                          ),
                        ],

                        if (step == 2) ...[
                          const Icon(
                            Icons.lock_reset_rounded,
                            color: orange,
                            size: 50,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Verifikasi berhasil. Silakan buat kata sandi baru.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          Form(
                            key: passwordFormKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: newPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Kata sandi baru',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 8) {
                                      return 'Minimal 8 karakter.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Konfirmasi kata sandi',
                                    prefixIcon: Icon(Icons.lock_reset),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Konfirmasi kata sandi wajib diisi.';
                                    }
                                    if (value != newPasswordController.text) {
                                      return 'Kata sandi belum cocok.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : step == 0
                            ? sendOtp
                            : step == 1
                                ? verifyOtp
                                : savePassword,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            step == 0
                                ? 'Kirim OTP'
                                : step == 1
                                    ? 'Verifikasi OTP'
                                    : 'Simpan Kata Sandi',
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    } finally {
    await Future.delayed(const Duration(milliseconds: 350));

    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}

}
