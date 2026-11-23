
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/location/screens/location_picker_screen.dart';
import 'package:laundry_go/features/location/services/geocoding_service.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';

class PartnerRegisterScreen extends StatefulWidget {
  final String phoneNumber;

  const PartnerRegisterScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<PartnerRegisterScreen> createState() =>
      _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState
    extends State<PartnerRegisterScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _businessNameController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _addressDetailController =
      TextEditingController();

  LatLng? _selectedLocation;

  final GeocodingService _geocodingService =
      GeocodingService();

  final AuthService _authService = AuthService();

  bool _isLoadingAddress = false;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedLocation = result;
      _isLoadingAddress = true;
    });

    try {
      final address = await _geocodingService
          .getAddressFromCoordinates(
        latitude: result.latitude,
        longitude: result.longitude,
      );

      if (!mounted) return;

      if (address == null || address.isEmpty) {
        throw Exception('Address not found.');
      }

      setState(() {
        _addressController.text = address;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat usaha berhasil ditemukan.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal mengambil alamat. Silakan coba lagi.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final fullName = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final businessName = _businessNameController.text.trim();
    final address = _addressController.text.trim();
    final addressDetail = _addressDetailController.text.trim();

    if (fullName.isEmpty) {
      _showMessage('Silakan masukkan nama lengkap.');
      return;
    }

    if (businessName.isEmpty) {
      _showMessage('Silakan masukkan nama usaha laundry.');
      return;
    }

    if (address.isEmpty) {
      _showMessage('Silakan masukkan alamat usaha.');
      return;
    }

    if (_selectedLocation == null) {
      _showMessage('Silakan pilih lokasi usaha di peta.');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      await _authService.registerPartner(
        fullName: fullName,
        phoneNumber: phoneNumber,
        businessName: businessName,
        address: address,
        addressDetail: addressDetail,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran mitra berhasil!'),
        ),
      );

      // Dashboard navigation will be added later.
    } catch (error, stackTrace) {
      debugPrint('Partner Registration Error: $error');
      debugPrint('Stack Trace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pendaftaran gagal: ${error.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
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

  // Build a reusable text field.
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
              ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled
                ? AppColors.deepNavy
                : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            filled: true,
            fillColor: enabled
                ? Colors.white
                : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
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
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Page title
              Text(
                'Buat Akun Mitra',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepNavy,
                    ),
              ),

              const SizedBox(height: 12),

              Text(
                'Lengkapi informasi diri dan usaha laundry kamu untuk bergabung dengan LaundryGo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),

              const SizedBox(height: 32),

              // Full name
              _buildTextField(
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap',
                controller: _nameController,
              ),

              const SizedBox(height: 24),

              // Phone number
              _buildTextField(
                label: 'Nomor Telepon',
                hint: 'Nomor HP',
                controller: _phoneController,
                enabled: false,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Business name
              _buildTextField(
                label: 'Nama Usaha Laundry',
                hint: 'Contoh: Laundry Bersih',
                controller: _businessNameController,
              ),

              const SizedBox(height: 24),

              // Business address
              _buildTextField(
                label: 'Alamat Usaha',
                hint: 'Masukkan alamat usaha',
                controller: _addressController,
                maxLines: 3,
              ),

              const SizedBox(height: 12),

              // Map location picker button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isLoadingAddress
                      ? null
                      : _openLocationPicker,
                  icon: _isLoadingAddress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.location_on_outlined),
                  label: Text(
                    _isLoadingAddress
                        ? 'Mengambil alamat...'
                        : 'Pilih di Peta',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Additional address details
              _buildTextField(
                label: 'Detail Alamat (Opsional)',
                hint: 'Contoh: Sebelah minimarket, lantai 2',
                controller: _addressDetailController,
                maxLines: 2,
              ),

              const SizedBox(height: 36),

              // Register button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isRegistering
                      ? null
                      : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isRegistering
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Daftar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
