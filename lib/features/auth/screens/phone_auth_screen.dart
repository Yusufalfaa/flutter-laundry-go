
import 'package:flutter/material.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/shared/widgets/app_button.dart';
import 'package:laundry_go/shared/widgets/app_text_field.dart';

import 'package:laundry_go/features/auth/services/auth_service.dart';
import 'package:laundry_go/features/auth/screens/customer_register_screen.dart';
import 'package:laundry_go/features/auth/screens/partner_register_screen.dart';

import 'package:laundry_go/features/partner/screens/partner_main_screen.dart';
import 'package:laundry_go/features/customer/screens/customer_main_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  final String role;

  const PhoneAuthScreen({
    super.key,
    required this.role,
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      _showMessage('Nomor HP wajib diisi.');
      return;
    }

    final phoneRegex = RegExp(r'^08[0-9]{8,11}$');

    if (!phoneRegex.hasMatch(phoneNumber)) {
      _showMessage('Masukkan nomor HP yang valid.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final existingUser =
          await _authService.checkPhoneNumber(phoneNumber);

      if (!mounted) return;

      if (existingUser != null) {
        final profile = await _authService.login(
          phoneNumber: phoneNumber,
          role: widget.role,
        );

        if (!mounted) return;

        if (widget.role == 'customer') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login berhasil. Selamat datang, ${profile['full_name'].toString().trim().split(' ').first}!',
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerMainScreen(),
            ),
            (route) => false,
          );
        } else if (widget.role == 'partner') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login berhasil. Selamat datang, ${profile['full_name'].toString().trim().split(' ').first}!',
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const PartnerMainScreen(),
            ),
            (route) => false,
          );
        }
        return;
      }

      if (widget.role == 'customer') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerRegisterScreen(
              phoneNumber: phoneNumber,
            ),
          ),
        );
      } else if (widget.role == 'partner') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartnerRegisterScreen(
              phoneNumber: phoneNumber,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      if (error.toString().contains('Account role does not match')) {
        _showMessage(
          'Nomor HP ini terdaftar untuk jenis akun yang berbeda.',
        );
      } else {
        _showMessage(
          'Terjadi kesalahan. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Back button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                  ),
                  color: Colors.white,
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              Text(
                'Masukkan Nomor Telepon',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepNavy,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Masukkan nomor HP yang akan digunakan untuk akun LaundryGo kamu.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              AppTextField(
                controller: _phoneController,
                label: 'Nomor HP',
                hint: 'Contoh: 081234567890',
                keyboardType: TextInputType.phone,
              ),

              const Spacer(),

              AppButton(
                text: _isLoading ? 'Memeriksa...' : 'Lanjutkan',
                onPressed: _isLoading ? null : _handleContinue,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
