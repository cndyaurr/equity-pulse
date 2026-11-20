import 'package:flutter/material.dart';

class KonsetPage extends StatelessWidget {
  final VoidCallback onHargaTap;
  final VoidCallback onPivotTap;
  final VoidCallback onKalkulatorTap;

  const KonsetPage({
    super.key,
    required this.onHargaTap,
    required this.onPivotTap,
    required this.onKalkulatorTap,
  });

  static const Color primaryColor = Color(0xFFF58220);
  static const Color backgroundColor = Color(0xFFF8F9FB);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          'Konset',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pusat Analisis Emas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Akses informasi harga emas, analisis pivot point, '
                'dan kalkulator untuk membantu perhitungan transaksi.',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildMenuCard(
                icon: Icons.candlestick_chart_rounded,
                title: 'Data Harga Emas',
                description:
                    'Lihat informasi harga emas dan pergerakan pasar terkini.',
                onTap: onHargaTap,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                icon: Icons.analytics_outlined,
                title: 'Pivot Point',
                description:
                    'Lihat hasil analisis pivot point, level support, dan resistance.',
                onTap: onPivotTap,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                icon: Icons.calculate_outlined,
                title: 'Kalkulator',
                description:
                    'Hitung estimasi transaksi emas digital dan emas fisik.',
                onTap: onKalkulatorTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: secondaryTextColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}