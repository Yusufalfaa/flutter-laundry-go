
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';

import '../widgets/partner_bottom_nav.dart';
import 'partner_orders_screen.dart';
import 'partner_services_screen.dart';
import 'partner_income_screen.dart';
import 'partner_store_screen.dart';

class PartnerMainScreen extends StatefulWidget {
  const PartnerMainScreen({super.key});

  @override
  State<PartnerMainScreen> createState() =>
      _PartnerMainScreenState();
}

class _PartnerMainScreenState extends State<PartnerMainScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  int _selectedIndex = 0;

  bool _isLoading = true;
  String? _partnerStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPartnerStatus();
  }

  Future<void> _loadPartnerStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _authService.getSession();

      if (session == null) {
        throw Exception('Session not found.');
      }

      final response = await _supabase
          .from('partners')
          .select('status')
          .eq('profile_id', session['id']!)
          .single();

      if (!mounted) return;

      setState(() {
        _partnerStatus = response['status'] as String;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPendingPage() {
    return Container(
      color: AppColors.background,
      width: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.starPromoBackground,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 46,
                  color: AppColors.starPromo,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dalam Masa Evaluasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pendaftaran tokomu sedang ditinjau oleh '
                'tim LaundryGo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan tunggu hingga akun mitramu '
                'disetujui untuk mengakses fitur ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.starPromoBackground,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 17,
                      color: AppColors.starPromo,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.starPromo,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextButton.icon(
                onPressed: _loadPartnerStatus,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Periksa Status'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Status Mitra',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPartnerStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isApproved = _partnerStatus == 'approved';

    final List<Widget> pages = [
      isApproved
          ? const PartnerOrdersScreen()
          : _buildPendingPage(),
      isApproved
          ? const PartnerServicesScreen()
          : _buildPendingPage(),
      isApproved
          ? const PartnerIncomeScreen()
          : _buildPendingPage(),
      const PartnerStoreScreen(),
    ];

    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _errorMessage != null
              ? _buildErrorPage()
              : IndexedStack(
                  index: _selectedIndex,
                  children: pages,
                ),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : PartnerBottomNav(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
    );
  }
}
