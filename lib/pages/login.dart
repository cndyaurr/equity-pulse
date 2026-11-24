import 'dart:async';
import '../services/notification_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_page.dart';
import 'daftar_akun_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
 bool rememberSession = true;
  bool isLoading = false;

  String? statusMessage;
  bool statusError = false;
  IconData statusIcon = Icons.info_outline;

  // Warna dari desain Stitch

  // Tema warna EWF
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showStatus(
    String message, {
    IconData icon = Icons.info_outline,
    bool error = false,
  }) {
    setState(() {
      statusMessage = message;
      statusIcon = icon;
      statusError = error;
    });
  }
Future<void> _registerFcmToken(String authToken) async {
  try {
    final fcmToken = await NotificationService.getDeviceToken();

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint('FCM token belum tersedia.');
      return;
    }

    final registered = await ApiService.registerDeviceToken(
      authToken: authToken,
      fcmToken: fcmToken,
      platform: 'android',
    );

    if (registered) {
      debugPrint('FCM token berhasil didaftarkan ke Laravel.');
    } else {
      debugPrint('FCM token gagal didaftarkan ke Laravel.');
    }
  } catch (e) {
    debugPrint('Gagal registrasi FCM: $e');
  }
}
  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showStatus(
        'Email dan kata sandi wajib diisi.',
        icon: Icons.warning_amber_rounded,
        error: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = null;
    });

    try {
      // Khusus Android Emulator yang mengakses server di laptop.

      // URL API untuk HP Android fisik.
      final baseUrl = ApiService.baseUrl;

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Login HTTP status: ${response.statusCode}');
      debugPrint('Login response: ${response.body}');

      final dynamic data;

      try {
        data = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          'Respons server bukan JSON yang valid. '
          'Periksa URL API dan konfigurasi backend.',
        );
      }

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true) {
        final token = data['token']?.toString();

        if (token == null || token.isEmpty) {
          throw Exception('Token login tidak ditemukan dari server.');
        }

        final prefs = await SharedPreferences.getInstance();

await prefs.setString('auth_token', token);
await prefs.setBool('remember_session', rememberSession);

unawaited(_registerFcmToken(token));

if (data['user'] is Map) {
  await prefs.setString('user_data', jsonEncode(data['user']));
}
        showStatus(
          'Login berhasil. Mengalihkan ke dashboard...',
          icon: Icons.check_circle_outline,
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              user: data['user'] is Map
                  ? Map<String, dynamic>.from(data['user'] as Map)
                  : null,
            ),
          ),
        );
      } else {
        final message = data is Map
            ? (data['message']?.toString() ??
                  'Login gagal. Periksa email dan kata sandi.')
            : 'Login gagal. Periksa konfigurasi API.';

        showStatus(message, icon: Icons.error_outline, error: true);
      }
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      showStatus('Koneksi login gagal: $e', icon: Icons.wifi_off, error: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }



  void triggerForgotFeedback() {
    final emailController = TextEditingController(
      text: this.emailController.text.trim(),
    );
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool dialogClosing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        int step = 0;
        bool loading = false;
        bool obscureNewPassword = true;
        bool obscureConfirmPassword = true;

        String? message;
        bool messageError = false;
        String verificationToken = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendOtp() async {
              final email = emailController.text.trim();

              if (!email.contains('@') || !email.contains('.')) {
                setDialogState(() {
                  message = 'Masukkan alamat email yang valid.';
                  messageError = true;
                });
                return;
              }

              setDialogState(() {
                loading = true;
                message = null;
              });

              try {
                final result =
                    await ApiService.requestForgotPasswordOtp(
                  email: email,
                );

                if (!dialogContext.mounted || dialogClosing) return;

                setDialogState(() {
                  if (result['success'] == true) {
                    step = 1;
                    message = result['message'] ??
                        'Jika email terdaftar, kode OTP akan dikirim.';
                    messageError = false;
                  } else {
                    message = result['message'] ??
                        'Gagal mengirim OTP. Silakan coba lagi.';
                    messageError = true;
                  }
                });
              } catch (e) {
                if (!dialogContext.mounted || dialogClosing) return;

                setDialogState(() {
                  message = 'Terjadi kesalahan: $e';
                  messageError = true;
                });
              } finally {
                if (!dialogClosing && dialogContext.mounted) {
                  setDialogState(() {
                    loading = false;
                  });
                }
              }
            }

            Future<void> verifyOtp() async {
              final otp = otpController.text.trim();

              if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                setDialogState(() {
                  message = 'Masukkan kode OTP yang terdiri dari 6 digit.';
                  messageError = true;
                });
                return;
              }

              setDialogState(() {
                loading = true;
                message = null;
              });

              try {
                final result =
                    await ApiService.verifyForgotPasswordOtp(
                  email: emailController.text.trim(),
                  otp: otp,
                );

                if (!dialogContext.mounted || dialogClosing) return;

                if (result['success'] == true &&
                    result['verification_token'] != null) {
                  setDialogState(() {
                    verificationToken =
                        result['verification_token'].toString();
                    step = 2;
                    message = 'OTP berhasil diverifikasi.';
                    messageError = false;
                  });
                } else {
                  setDialogState(() {
                    message = result['message'] ??
                        'Verifikasi OTP gagal.';
                    messageError = true;
                  });
                }
              } catch (e) {
                if (!dialogContext.mounted || dialogClosing) return;

                setDialogState(() {
                  message = 'Terjadi kesalahan: $e';
                  messageError = true;
                });
              } finally {
                if (!dialogClosing && dialogContext.mounted) {
                  setDialogState(() {
                    loading = false;
                  });
                }
              }
            }

            Future<void> resetPassword() async {
              final password = newPasswordController.text;
              final confirmPassword =
                  confirmPasswordController.text;

              if (password.length < 8) {
                setDialogState(() {
                  message = 'Password minimal terdiri dari 8 karakter.';
                  messageError = true;
                });
                return;
              }

              if (password != confirmPassword) {
                setDialogState(() {
                  message = 'Konfirmasi password tidak cocok.';
                  messageError = true;
                });
                return;
              }

              if (verificationToken.isEmpty) {
                setDialogState(() {
                  message = 'Token verifikasi tidak ditemukan. '
                      'Silakan ulangi verifikasi OTP.';
                  messageError = true;
                });
                return;
              }

              setDialogState(() {
                loading = true;
                message = null;
              });

              try {
                final result =
                    await ApiService.resetForgotPassword(
                  email: emailController.text.trim(),
                  verificationToken: verificationToken,
                  newPassword: password,
                  confirmPassword: confirmPassword,
                );

                if (!dialogContext.mounted || dialogClosing) return;

                if (result['success'] == true) {
                  dialogClosing = true;

                  Navigator.pop(dialogContext);

                  if (mounted) {
                    passwordController.clear();

                    showStatus(
                      'Password berhasil diperbarui. Silakan login kembali.',
                      icon: Icons.check_circle_outline,
                    );
                  }

                  return;
                } else {
                  setDialogState(() {
                    message = result['message'] ??
                        'Gagal memperbarui password.';
                    messageError = true;
                  });
                }
              } catch (e) {
                if (!dialogContext.mounted || dialogClosing) return;

                setDialogState(() {
                  message = 'Terjadi kesalahan: $e';
                  messageError = true;
                });
              } finally {
                if (!dialogClosing && dialogContext.mounted) {
                  setDialogState(() {
                    loading = false;
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: surfaceContainerLowest,
              icon: const Icon(
                Icons.lock_reset,
                color: primary,
                size: 36,
              ),
              title: Text(
                step == 0
                    ? 'Lupa Password'
                    : step == 1
                        ? 'Verifikasi OTP'
                        : 'Password Baru',
                style: jakarta(
                  size: 20,
                  weight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (step == 0) ...[
                        Text(
                          'Masukkan email yang terdaftar. '
                          'Kami akan mengirimkan kode OTP untuk '
                          'memulihkan password akun kamu.',
                          style: jakarta(
                            size: 14,
                            color: onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Alamat email',
                            hintText: 'nama@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

                      if (step == 1) ...[
                        Text(
                          'Masukkan kode OTP 6 digit yang dikirim '
                          'ke email:',
                          style: jakarta(
                            size: 14,
                            color: onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          emailController.text.trim(),
                          style: jakarta(
                            size: 14,
                            weight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Kode OTP',
                            hintText: 'Masukkan 6 digit OTP',
                            prefixIcon: Icon(Icons.password),
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: loading ? null : sendOtp,
                            child: const Text('Kirim ulang OTP'),
                          ),
                        ),
                      ],

                      if (step == 2) ...[
                        Text(
                          'Buat password baru untuk akun kamu.',
                          style: jakarta(
                            size: 14,
                            color: onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: newPasswordController,
                          obscureText: obscureNewPassword,
                          enabled: !loading,
                          decoration: InputDecoration(
                            labelText: 'Password baru',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscureNewPassword =
                                      !obscureNewPassword;
                                });
                              },
                              icon: Icon(
                                obscureNewPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          enabled: !loading,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi password baru',
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Password minimal 8 karakter.',
                          style: jakarta(
                            size: 12,
                            color: secondary,
                          ),
                        ),
                      ],

                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: messageError
                                ? const Color(0xFFFFDAD6)
                                : surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message!,
                            style: jakarta(
                              size: 13,
                              color: messageError
                                  ? const Color(0xFF93000A)
                                  : onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          if (step == 1) {
                            setDialogState(() {
                              step = 0;
                              message = null;
                              otpController.clear();
                            });
                          } else {
                            dialogClosing = true;
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: Text(
                    step == 0 ? 'Batal' : 'Kembali',
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: loading
                      ? null
                      : step == 0
                          ? sendOtp
                          : step == 1
                              ? verifyOtp
                              : resetPassword,
                  child: loading
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
                                  : 'Simpan Password',
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      emailController.dispose();
      otpController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }



  void triggerHelpFeedback() {
    showStatus(
      'Helpdesk Operasional: itsupport.equicklye@gmail.com | Hunting: +6285749963720',
      icon: Icons.contact_support_outlined,
    );
  }

  TextStyle jakarta({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = onSurface,
  }) {
    return GoogleFonts.roboto(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.25,
    );
  }

  TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color color = onSurface,
  }) {
    return GoogleFonts.roboto(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.25,
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: jakarta(size: 14, weight: FontWeight.w400, color: secondary),
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

            // Lapisan putih agar UI tetap terbaca
            Container(color: Colors.white.withValues(alpha: 0.40)),

            // Konten login
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
                        _buildLoginCard(),
                        const SizedBox(height: 16),
                        _buildSupportCard(),
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
                      TextSpan(
                        text: 'EQUICKLY',
                        style: TextStyle(color: primary),
                      ),
                    ],
                  ),
                ),
                Text(
                  'MARKET INTELLIGENCE',
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

  Widget _buildLoginCard() {
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
          // Garis gold atas
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
                        'Masuk ke Platform',
                        style: jakarta(size: 20, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  'Internal Portal PT Equityworld Futures',
                  style: jakarta(size: 14, color: onSurfaceVariant),
                ),

                const SizedBox(height: 20),

                // Email
                Text(
                  'Email Anda',
                  style: jakarta(size: 14, weight: FontWeight.w500),
                ),

                const SizedBox(height: 4),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: onSurface,
                  ),
                  decoration: inputDecoration(
                    hint: 'nama.pengguna@gmail.com',
                    icon: Icons.badge_outlined,
                  ),
                ),

                const SizedBox(height: 16),

                // Password + lupa password
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kata Sandi',
                        style: jakarta(size: 14, weight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: triggerForgotFeedback,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Lupa Password?',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: mono(size: 16),
                  decoration: inputDecoration(
                    hint: '••••••••••••',
                    icon: Icons.key_outlined,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: secondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Remember session
                Row(
                  children: [
                    Checkbox(
                      value: rememberSession,
                      activeColor: primary,
                      onChanged: (value) {
                        setState(() {
                          rememberSession = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Ingat sesi di perangkat aman ini',
                        style: jakarta(size: 14, color: onSurface),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Tombol login
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
                      onPressed: isLoading ? null : handleLogin,
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
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Memverifikasi Otorisasi...',
                                  style: jakarta(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_user_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Masuk ke Equickly',
                                  style: jakarta(
                                    size: 16,
                                    weight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                // Status message
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
                              : statusIcon,
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
                              size: 14,
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

                const SizedBox(height: 16),

                // Tombol menuju halaman pendaftaran
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Belum memiliki akun? ',
                        style: jakarta(size: 14, color: secondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DaftarAkunPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Daftar di sini',
                          style: jakarta(
                            size: 14,
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

          // Security panel
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
                      style: jakarta(size: 12, color: onSurfaceVariant),
                      children: const [
                        TextSpan(
                          text: 'Sistem Informasi Internal Terproteksi',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' • Khusus Karyawan & Analis PT Equityworld Futures. Seluruh sesi diaudit secara digital.',
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
                  style: jakarta(size: 12, weight: FontWeight.w600),
                ),
                Text(
                  'Ext. 4410 (Equity Tower LT. 22)',
                  style: jakarta(size: 14, color: secondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: triggerHelpFeedback,
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
              style: jakarta(size: 12, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
