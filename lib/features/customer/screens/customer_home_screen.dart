
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  final ValueChanged<String> onServiceSelected;
  final VoidCallback onViewAllOrders;

  const CustomerHomeScreen({
    super.key,
    required this.onServiceSelected,
    required this.onViewAllOrders,
  });

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

  final List<Map<String, dynamic>> _activeOrders = [];

  bool _isLoadingOrders = true;
  String? _orderError;

  static const List<String> _activeStatuses = [
    'pending',
    'confirmed',
    'pickup',
    'processing',
    'delivering',
  ];

  @override
  void initState() {
    super.initState();

    _loadUserSession();
    _loadActiveOrders();
    _startPromotionAutoScroll();
  }

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

  Future<void> _loadUserSession() async {
    try {
      final session = await _authService.getSession();

      if (!mounted) return;

      if (session != null) {
        final fullName = session['full_name']?.trim() ?? '';
        final nameParts = fullName
            .split(' ')
            .where((word) => word.isNotEmpty)
            .toList();

        setState(() {
          _firstName =
              nameParts.isNotEmpty ? nameParts.first : 'Pengguna';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Failed to load user session: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActiveOrders() async {
    try {
      final session = await _authService.getSession();

      if (session == null || session['id'] == null) {
        if (!mounted) return;

        setState(() {
          _activeOrders.clear();
          _isLoadingOrders = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('orders')
          .select('''
            id,
            status,
            created_at,
            partners(business_name),
            order_items(service_name)
          ''')
          .eq('customer_id', session['id']!)
          .inFilter('status', _activeStatuses)
          .order('created_at', ascending: false)
          .limit(1);

      if (!mounted) return;

      setState(() {
        _activeOrders
          ..clear()
          ..addAll(
            List<Map<String, dynamic>>.from(response),
          );

        _isLoadingOrders = false;
        _orderError = null;
      });
    } catch (error) {
      debugPrint('Failed to load active orders: $error');

      if (!mounted) return;

      setState(() {
        _isLoadingOrders = false;
        _orderError = 'Gagal memuat pesanan.';
      });
    }
  }

  @override
  void dispose() {
    _promotionTimer?.cancel();
    _promotionController.dispose();
    super.dispose();
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
    required String serviceType,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          widget.onServiceSelected(serviceType);
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Pesanan Dikonfirmasi';
      case 'pickup':
        return 'Dalam Penjemputan';
      case 'processing':
        return 'Sedang Dicuci';
      case 'delivering':
        return 'Dalam Pengantaran';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.starPromo;
      case 'confirmed':
        return AppColors.primary;
      case 'pickup':
        return Colors.deepPurple;
      case 'processing':
        return Colors.blue;
      case 'delivering':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';

    final partner = order['partners'];
    final partnerName = partner is Map
        ? partner['business_name']?.toString() ?? 'Mitra Laundry'
        : 'Mitra Laundry';

    final items = order['order_items'] as List? ?? [];

    final serviceNames = items
        .map((item) => item['service_name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .join(', ');

    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_laundry_service_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  partnerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          if (serviceNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              serviceNames,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusLabel(status),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
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
              onPressed: widget.onViewAllOrders,
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
        const SizedBox(height: 8),

        if (_isLoadingOrders)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          )
        else if (_orderError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  _orderError!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoadingOrders = true;
                    });
                    _loadActiveOrders();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          )
        else if (_activeOrders.isEmpty)
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
          )
        else
          ..._activeOrders.map(_buildOrderCard),
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
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
                    serviceType: 'by_weight',
                  ),
                  const SizedBox(width: 12),
                  _buildServiceCard(
                    icon: Icons.checkroom_rounded,
                    title: 'Laundry Satuan',
                    subtitle: 'Berdasarkan jumlah item',
                    serviceType: 'by_item',
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
