
import 'package:flutter/material.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/auth/screens/welcome_screen.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerStoreScreen extends StatefulWidget {
  const PartnerStoreScreen({super.key});

  @override
  State<PartnerStoreScreen> createState() =>
      _PartnerStoreScreenState();
}

class _PartnerStoreScreenState extends State<PartnerStoreScreen> {
  final AuthService _authService = AuthService();

  String _fullName = 'Mitra Laundry';
  String _phoneNumber = '';
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _partnerStatus;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    try {
      final session = await _authService.getSession();

      if (session == null) {
        throw Exception('User session not found.');
      }

      final partner = await Supabase.instance.client
          .from('partners')
          .select('status')
          .eq('profile_id', session['id']!)
          .single();

      if (!mounted) return;

      setState(() {
        _fullName = session['full_name'] ?? 'Mitra Laundry';
        _phoneNumber = session['phone_number'] ?? '';
        _partnerStatus = partner['status'] as String?;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load User Session Error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun LaundryGo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      debugPrint('Logout Error: $error');

      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal logout. Silakan coba kembali.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title akan segera tersedia.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.aquaTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoading ? 'Memuat...' : _fullName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _phoneNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _partnerStatus == 'approved'
                        ? AppColors.aquaTint
                        : AppColors.starPromoBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _partnerStatus == 'approved'
                        ? 'Mitra LaundryGo'
                        : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _partnerStatus == 'approved'
                          ? AppColors.primary
                          : AppColors.starPromo,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.deepNavy,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDanger
                  ? AppColors.danger
                  : AppColors.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDanger
                      ? AppColors.danger
                      : AppColors.deepNavy,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toko Saya',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 20),

              _buildProfileHeader(),

              _buildSectionTitle('Pengaturan Toko'),
              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.store_outlined,
                  title: 'Info Toko',
                  onTap: () => _showComingSoon('Info Toko'),
                ),
                const Divider(height: 1, indent: 50),
                _buildMenuItem(
                  icon: Icons.access_time_rounded,
                  title: 'Jam Operasional',
                  onTap: () => _showComingSoon('Jam Operasional'),
                ),
                const Divider(height: 1, indent: 50),
                _buildMenuItem(
                  icon: Icons.delivery_dining_rounded,
                  title: 'Area Antar Jemput',
                  onTap: () => _showComingSoon('Area Antar Jemput'),
                ),
                const Divider(height: 1, indent: 50),
                _buildMenuItem(
                  icon: Icons.account_balance_outlined,
                  title: 'Rekening Pencairan',
                  onTap: () => _showComingSoon('Rekening Pencairan'),
                ),
              ]),

              _buildSectionTitle('Bantuan & Lainnya'),
              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'Bantuan Mitra',
                  onTap: () => _showComingSoon('Bantuan Mitra'),
                ),
                const Divider(height: 1, indent: 50),
                _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: _isLoggingOut ? 'Logging out...' : 'Logout',
                  isDanger: true,
                  onTap: _isLoggingOut ? () {} : _handleLogout,
                ),
              ]),

              const SizedBox(height: 28),

              Center(
                child: Image.asset(
                  'assets/images/logos/laundrygo_brand_horizontal.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
