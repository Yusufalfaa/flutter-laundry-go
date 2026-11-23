import 'dart:async';

import 'package:flutter/material.dart';
import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() =>
      _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final AuthService _authService = AuthService();

  final PageController _promotionController = PageController();
  Timer? _promotionTimer;

  int _currentPromotionIndex = 0;

  String _firstName = 'Pengguna';
  bool _isLoading = true;

  final List<Map<String, String>> _promotions = [
    {
      'title': 'Laundry Jadi Lebih Mudah',
      'subtitle': 'Temukan layanan laundry terbaik di sekitarmu.',
    },
    {
      'title': 'Temukan Mitra Laundry',
      'subtitle': 'Pilih layanan sesuai kebutuhanmu.',
    },
    {
      'title': 'Waktunya Laundry!',
      'subtitle': 'Serahkan urusan pakaianmu kepada ahlinya.',
    },
  ];

  void _startPromotionAutoScroll() {
    _promotionTimer?.cancel();

    _promotionTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        if (!mounted || !_promotionController.hasClients) return;

        final currentPage =
            _promotionController.page?.round() ?? 0;

        _promotionController.animateToPage(
          currentPage + 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _startPromotionAutoScroll();
  }

  Future<void> _loadUserSession() async {
    try {
      final session = await _authService.getSession();

      if (!mounted) return;

      if (session != null) {
        final fullName = session['full_name']?.trim() ?? '';
        final firstName = fullName
            .split(' ')
            .where((word) => word.isNotEmpty)
            .firstOrNull;

        setState(() {
          _firstName = firstName?.isNotEmpty == true
              ? firstName!
              : 'Pengguna';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToTab(int index) {
    final mainScreenState = context.findAncestorStateOfType<
        State<StatefulWidget>>();

    // Tab navigation will be connected through a callback.
  }

  Widget _buildHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/logos/laundrygo_brand_horizontal.png',
        height: 42,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildPromotionCarousel() {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _promotionController,
        itemCount: null,
        onPageChanged: (index) {
          setState(() {
            _currentPromotionIndex =
                index % _promotions.length;
          });
        },
        itemBuilder: (context, index) {
          final promotion =
              _promotions[index % _promotions.length];

          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryBright,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        promotion['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promotion['subtitle']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Icon(
                    Icons.local_laundry_service_rounded,
                    color: Colors.white,
                    size: 65,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _promotionTimer?.cancel();
    _promotionController.dispose();
    super.dispose();
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLoading ? 'Halo, ... 👋' : 'Halo, $_firstName! 👋',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Mau laundry apa hari ini?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // Search tab navigation will be connected later.
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.aquaTint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pesanan Berlangsung',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.deepNavy,
              ),
            ),
            TextButton(
              onPressed: () {
                // Orders tab navigation will be connected later.
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 26,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 42,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 12),
              Text(
                'Belum ada pesanan berlangsung',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Pesanan laundry kamu akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              _buildPromotionCarousel(),
              const SizedBox(height: 10),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _promotions.length,
                    (index) {
                      final isActive =
                          _currentPromotionIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 26),
              _buildGreeting(),
              
              const SizedBox(height: 22),
              const Text(
                'Pilih Layanan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceCard(
                    icon: Icons.scale_rounded,
                    title: 'Laundry Kiloan',
                    subtitle: 'Berdasarkan berat (kg)',
                  ),
                  const SizedBox(width: 12),
                  _buildServiceCard(
                    icon: Icons.checkroom_rounded,
                    title: 'Laundry Satuan',
                    subtitle: 'Berdasarkan jumlah item',
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _buildActiveOrdersSection(),
            ],
          ),
        ),
      ),
    );
  }
}
