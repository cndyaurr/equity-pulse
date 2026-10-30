import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class DaftarAkunPage extends StatefulWidget {
  const DaftarAkunPage({super.key});

  @override
  State<DaftarAkunPage> createState() => _DaftarAkunPageState();
}

class _DaftarAkunPageState extends State<DaftarAkunPage> {
  final namaController = TextEditingController();
  final unitKantorController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool obscurePassword = true;
  bool obscureKonfirmasi = true;
  bool setuju = false;
  bool isLoading = false;

  String? statusMessage;
  bool statusError = false;

  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFFFE5CC);
  static const Color surfaceContainerLow = Color(0xFFFFF3E8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFFF58220);
  static const Color primaryContainer = Color(0xFFD96812);
  static const Color primaryFixed = Color(0xFFFFC58A);

  static const Color onSurface = Color(0xFF1F2937);
  static const Color onSurfaceVariant = Color(0xFF475569);
  static const Color secondary = Color(0xFF64748B);

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    unitKantorController.dispose();
    passwordController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  TextStyle jakarta({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = onSurface,
  }) {
    return GoogleFonts.roboto(fontSize: size, fontWeight: weight, color: color);
  }

  TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color color = onSurface,
  }) {
    return GoogleFonts.roboto(fontSize: size, fontWeight: weight, color: color);
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: jakarta(size: 12, weight: FontWeight.w400, color: secondary),
      prefixIcon: Icon(icon, color: secondary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget fieldLabel(String text) {
    return Text(text, style: jakarta(size: 11, weight: FontWeight.w500));
  }

  Widget buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText ?? false,
          style: jakarta(size: 12),
          decoration: inputDecoration(
            hint: hint,
            icon: icon,
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      obscureText!
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: secondary,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  void showStatus(String message, {bool error = false}) {
    if (!mounted) return;

    setState(() {
      statusMessage = message;
      statusError = error;
    });
  }

  Future<void> handleDaftar() async {
    if (isLoading) return;

    final nama = namaController.text.trim();
    final email = emailController.text.trim();
    final unitKantor = unitKantorController.text.trim();
    final password = passwordController.text;
    final konfirmasi = konfirmasiController.text;

    if (nama.isEmpty ||
        email.isEmpty ||
        unitKantor.isEmpty ||
        password.isEmpty ||
        konfirmasi.isEmpty) {
      showStatus('Harap lengkapi seluruh data pendaftaran.', error: true);
      return;
    }

    final emailValid = RegExp(
      r'^[A-Z0-9._%+-]+@gmail\.com$',
      caseSensitive: false,
    ).hasMatch(email);

    if (!emailValid) {
      showStatus('Gunakan email dengan domain @gmail.com', error: true);
      return;
    }

    if (password.length < 8) {
      showStatus('Kata sandi minimal terdiri dari 8 karakter.', error: true);
      return;
    }

    if (password != konfirmasi) {
      showStatus('Konfirmasi kata sandi tidak sesuai.', error: true);
      return;
    }

    if (!setuju) {
      showStatus(
        'Harap setujui ketentuan pendaftaran terlebih dahulu.',
        error: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = null;
    });

    try {
      // Alamat API untuk emulator Android.
      const baseUrl = 'http://10.0.2.2:8000/api';

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': namaController.text.trim(),
          'email': emailController.text.trim(),
          'work_location': unitKantorController.text.trim(),
          'password': passwordController.text,
          'password_confirmation': konfirmasiController.text,
        }),
      );

      debugPrint('URL REGISTER: ${response.request?.url}');
      debugPrint('STATUS REGISTER: ${response.statusCode}');
      debugPrint('BODY REGISTER: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        showStatus(
          data['message'] ??
              'Pendaftaran berhasil. Silakan cek email untuk verifikasi akun.',
        );

        // Kosongkan form setelah pendaftaran berhasil.
        namaController.clear();
        emailController.clear();
        unitKantorController.clear();
        passwordController.clear();
        konfirmasiController.clear();

        setState(() {
          setuju = false;
        });
      } else {
        String message =
            data['message'] ?? 'Pendaftaran gagal. Silakan coba kembali.';

        // Tampilkan detail validasi dari Laravel jika tersedia.
        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              message = firstError.first.toString();
            }
          }
        }

        showStatus(message, error: true);
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR DAFTAR AKUN: $e');
      debugPrint('DETAIL ERROR: $stackTrace');

      showStatus('Terjadi error: $e', error: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        textTheme: GoogleFonts.robotoTextTheme(baseTheme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: surface,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background trading
            Image.asset(
              'assets/images/trading_background.png',
              fit: BoxFit.cover,
            ),

            // Lapisan putih transparan
            Container(color: Colors.white.withValues(alpha: 0.40)),

            // Konten pendaftaran
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        _buildBranding(),
                        const SizedBox(height: 8),
                        _buildRegisterCard(),
                        const SizedBox(height: 16),
                        _buildSupportCard(),
                        const SizedBox(height: 32),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        const SizedBox(height: 4),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo perusahaan
            SizedBox(
              width: 48,
              height: 48,
              child: Image.asset(
                'assets/images/logo_perusahaan.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.business, color: primary, size: 28);
                },
              ),
            ),

            const SizedBox(width: 24),

            // Nama perusahaan
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                    children: const [
                      TextSpan(text: 'EQUITY '),
                      TextSpan(
                        text: 'PULSE',
                        style: TextStyle(color: primary),
                      ),
                    ],
                  ),
                ),
                Text(
                  'PT EQUITYWORLD FUTURES',
                  style: jakarta(
                    size: 14,
                    weight: FontWeight.w500,
                    color: secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 4),
            color: Color(0x18000000),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryContainer, primary, primaryFixed],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Daftar Akun',
                        style: jakarta(size: 20, weight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'v4.8.2',
                        style: mono(size: 11, color: onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Registrasi Internal PT Equityworld Futures',
                  style: jakarta(size: 13, color: onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                buildTextField(
                  label: 'Nama Lengkap',
                  hint: 'Nama sesuai identitas perusahaan',
                  icon: Icons.person_outline,
                  controller: namaController,
                ),
                const SizedBox(height: 16),

                buildTextField(
                  label: 'Email Perusahaan',
                  hint: 'nama.pengguna@gmail.com',
                  icon: Icons.badge_outlined,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),

                buildTextField(
                  label: 'Lokasi Kerja / Kantor',
                  hint: 'Contoh: Surabaya - Trilium Office Lt. 2',
                  icon: Icons.business_outlined,
                  controller: unitKantorController,
                ),

                const SizedBox(height: 16),

                buildTextField(
                  label: 'Kata Sandi',
                  hint: 'Minimal 8 karakter',
                  icon: Icons.key_outlined,
                  controller: passwordController,
                  isPassword: true,
                  obscureText: obscurePassword,
                  onToggle: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 16),

                buildTextField(
                  label: 'Konfirmasi Kata Sandi',
                  hint: 'Masukkan ulang kata sandi',
                  icon: Icons.lock_outline,
                  controller: konfirmasiController,
                  isPassword: true,
                  obscureText: obscureKonfirmasi,
                  onToggle: () {
                    setState(() {
                      obscureKonfirmasi = !obscureKonfirmasi;
                    });
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Checkbox(
                        value: setuju,
                        activeColor: primary,
                        onChanged: (value) {
                          setState(() {
                            setuju = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Saya menyatakan bahwa data yang diisi '
                          'benar dan bersedia mengikuti proses '
                          'verifikasi akun.',
                          style: jakarta(size: 12, color: onSurface),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryContainer, primary, primaryContainer],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleDaftar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_add_alt_1, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Ajukan Pendaftaran',
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                if (statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusError
                          ? const Color(0xFFFFDAD6)
                          : surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          statusError
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline,
                          size: 18,
                          color: statusError
                              ? const Color(0xFFBA1A1A)
                              : primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusMessage!,
                            style: jakarta(
                              size: 12,
                              color: statusError
                                  ? const Color(0xFF93000A)
                                  : onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Sudah memiliki akun? ',
                        style: jakarta(size: 12, color: secondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Masuk di sini',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: surfaceContainerLow,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: jakarta(size: 10, color: onSurfaceVariant),
                      children: const [
                        TextSpan(
                          text: 'Verifikasi Akses Internal',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' • Pendaftaran akan diperiksa '
                              'sebelum akses platform diberikan.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/logo_perusahaan.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.business, color: primary, size: 28);
              },
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IT Desk Support',
                  style: jakarta(size: 10, weight: FontWeight.w600),
                ),
                Text(
                  'Ext. 4410 (Equity Tower LT. 22)',
                  style: jakarta(size: 11, color: secondary),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: () {
              showStatus(
                'Silakan hubungi IT Desk Support untuk '
                'bantuan pendaftaran akun.',
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: surfaceContainer,
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'Bantuan',
              style: jakarta(size: 10, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Terdaftar & Diawasi oleh Bappebti • Anggota ICDX & ICH',
          textAlign: TextAlign.center,
          style: jakarta(size: 10, weight: FontWeight.w600, color: onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2025 PT Equityworld Futures. '
          'Hak Cipta Dilindungi Undang-Undang.',
          textAlign: TextAlign.center,
          style: jakarta(size: 10, color: secondary),
        ),
      ],
    );
  }
}
