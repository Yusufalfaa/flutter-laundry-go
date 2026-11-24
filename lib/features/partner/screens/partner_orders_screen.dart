
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';

class PartnerOrdersScreen extends StatefulWidget {
  const PartnerOrdersScreen({super.key});

  @override
  State<PartnerOrdersScreen> createState() =>
      _PartnerOrdersScreenState();
}

class _PartnerOrdersScreenState extends State<PartnerOrdersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  int _selectedFilter = 0;

  bool? _isStoreOpen;
  bool _isLoadingStoreStatus = true;
  bool _isStoreStatusAvailable = true;

  final List<String> _filters = [
    'Semua',
    'Baru',
    'Diproses',
    'Siap Diambil',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    _loadStoreStatus();
  }

  Future<void> _loadStoreStatus() async {
    try {
      final session = await _authService.getSession();

      if (session == null) {
        throw Exception('User session not found.');
      }

      final profileId = session['id'];

      if (profileId == null) {
        throw Exception('Profile ID not found.');
      }

      final response = await _supabase
          .from('partners')
          .select('is_open')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _isStoreOpen = response?['is_open'] as bool? ?? false;
        _isStoreStatusAvailable = response != null;
        _isLoadingStoreStatus = false;
      });
    } catch (error) {
      debugPrint('Load Store Status Error: $error');

      if (!mounted) return;

      setState(() {
        _isStoreStatusAvailable = false;
        _isLoadingStoreStatus = false;
      });
    }
  }

  Widget _buildHeader() {
    final String statusLabel = _isLoadingStoreStatus
        ? 'MEMUAT...'
        : !_isStoreStatusAvailable
            ? 'TIDAK TERSEDIA'
            : _isStoreOpen == true
                ? 'TOKO BUKA'
                : 'TOKO TUTUP';

    final Color statusColor = _isLoadingStoreStatus ||
            !_isStoreStatusAvailable
        ? AppColors.textSecondary
        : _isStoreOpen == true
            ? AppColors.success
            : AppColors.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logos/laundrygo_brand_horizontal.png',
            height: 38,
            fit: BoxFit.contain,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  statusLabel,
                  style: const TextStyle(
                    color: AppColors.deepNavy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.75),
            size: 27,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(
              color: AppColors.deepNavy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.15,
            children: [
              _buildSummaryCard(
                title: 'Pesanan Baru',
                count: '0',
                icon: Icons.inbox_outlined,
              ),
              _buildSummaryCard(
                title: 'Diproses',
                count: '0',
                icon: Icons.local_laundry_service_outlined,
              ),
              _buildSummaryCard(
                title: 'Siap Diambil',
                count: '0',
                icon: Icons.inventory_2_outlined,
              ),
              _buildSummaryCard(
                title: 'Selesai',
                count: '0',
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(int index) {
    final bool isSelected = _selectedFilter == index;

    return ChoiceChip(
      label: Text(_filters[index]),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = index;
        });
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : AppColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: isSelected
            ? FontWeight.w700
            : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Pesanan',
          style: TextStyle(
            color: AppColors.deepNavy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              _filters.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  right: index == _filters.length - 1 ? 0 : 8,
                ),
                child: _buildFilterButton(index),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final String title = _selectedFilter == 0
        ? 'Belum Ada Pesanan'
        : 'Belum Ada Pesanan ${_filters[_selectedFilter]}';

    const String description =
        'Pesanan yang masuk akan muncul di halaman ini.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.aquaTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepNavy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildOrderSummary(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilters(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildEmptyState(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
