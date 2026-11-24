
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';
import 'package:laundry_go/features/location/screens/location_picker_screen.dart';
import 'package:laundry_go/features/location/services/geocoding_service.dart';

import 'package:laundry_go/features/customer/screens/order_success_screen.dart';

class CustomerOrderFormScreen extends StatefulWidget {
  final Map<String, dynamic> partner;
  final List<Map<String, dynamic>> selectedServices;

  const CustomerOrderFormScreen({
    super.key,
    required this.partner,
    required this.selectedServices,
  });

  @override
  State<CustomerOrderFormScreen> createState() =>
      _CustomerOrderFormScreenState();
}

class _CustomerOrderFormScreenState
    extends State<CustomerOrderFormScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  final GeocodingService _geocodingService = GeocodingService();

  final TextEditingController _addressDetailController =
      TextEditingController();
  final TextEditingController _notesController =
      TextEditingController();

  String _customerAddress = '';
  String? _customerId;

  double? _latitude;
  double? _longitude;

  bool _isLoading = true;
  bool _isSelectingLocation = false;
  bool _isSubmitting = false;

  bool get _hasItemService {
    return widget.selectedServices.any(
      (service) => service['service_type'] == 'by_item',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCustomerProfile();
  }

  @override
  void dispose() {
    _addressDetailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerProfile() async {
    try {
      final session = await _authService.getSession();

      if (session == null) {
        throw Exception('Customer session was not found.');
      }

      final profile = await _supabase
          .from('profiles')
          .select(
            'id, address, address_detail, latitude, longitude',
          )
          .eq('id', session['id']!)
          .single();

      if (!mounted) return;

      setState(() {
        _customerId = profile['id'] as String;
        _customerAddress = profile['address'] ?? '';
        _addressDetailController.text =
            profile['address_detail'] ?? '';

        _latitude = (profile['latitude'] as num?)?.toDouble();
        _longitude = (profile['longitude'] as num?)?.toDouble();

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load customer address: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectLocation() async {
    final LatLng? initialLocation =
        _latitude != null && _longitude != null
            ? LatLng(_latitude!, _longitude!)
            : null;

    final selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: initialLocation,
        ),
      ),
    );

    if (selectedLocation == null || !mounted) return;

    setState(() {
      _isSelectingLocation = true;
      _latitude = selectedLocation.latitude;
      _longitude = selectedLocation.longitude;
    });

    try {
      final address =
          await _geocodingService.getAddressFromCoordinates(
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
      );

      if (!mounted) return;

      setState(() {
        _customerAddress = address ?? '';
      });

      if (_customerAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address could not be retrieved.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to retrieve address. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingLocation = false;
        });
      }
    }
  }

  String _serviceName(String serviceType) {
    switch (serviceType) {
      case 'by_weight':
        return 'Laundry Kiloan';
      case 'by_item':
        return 'Laundry Satuan';
      default:
        return 'Laundry';
    }
  }

  String _formatPrice(dynamic value) {
    final price = (value as num?)?.toDouble() ?? 0;
    return 'Rp ${price.toStringAsFixed(0)}';
  }

  Future<void> _submitOrder() async {
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer data is not available.'),
        ),
      );
      return;
    }

    if (_customerAddress.trim().isEmpty ||
        _latitude == null ||
        _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your delivery address.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_hasItemService && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please describe the clothing items and quantities.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final order = await _supabase
          .from('orders')
          .insert({
            'customer_id': _customerId,
            'partner_id': widget.partner['id'],
            'status': 'pending',
            'customer_address': _customerAddress.trim(),
            'customer_address_detail':
                _addressDetailController.text.trim(),
            'customer_latitude': _latitude,
            'customer_longitude': _longitude,
            'subtotal': 0,
            'platform_fee': 0,
            'total_amount': 0,
            'notes': _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          })
          .select('id, order_number')
          .single();

      final orderItems = widget.selectedServices.map((service) {
        final serviceType = service['service_type'] as String;
        final unitPrice = (service['price'] as num).toDouble();

        return {
          'order_id': order['id'],
          'service_id': service['id'],
          'service_name': _serviceName(serviceType),
          'quantity': 0,
          'unit_price': unitPrice,
          'line_total': 0,
        };
      }).toList();

      await _supabase.from('order_items').insert(orderItems);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create order: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.deepNavy,
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Alamat Penjemputan'),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lokasi Penjemputan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSelectingLocation
                        ? null
                        : _selectLocation,
                    child: const Text('Ubah'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isSelectingLocation)
                const LinearProgressIndicator()
              else
                Text(
                  _customerAddress.isEmpty
                      ? 'Belum ada alamat. Silakan pilih lokasi.'
                      : _customerAddress,
                  style: TextStyle(
                    fontSize: 13,
                    color: _customerAddress.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.deepNavy,
                  ),
                ),

              const SizedBox(height: 14),

              TextField(
                controller: _addressDetailController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Detail Alamat (Opsional)',
                  hintText: 'Contoh: Kos nomor 12, lantai 2',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Layanan yang Dipilih'),

        ...widget.selectedServices.map((service) {
          final serviceType = service['service_type'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_laundry_service,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _serviceName(serviceType),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serviceType == 'by_weight'
                            ? 'Tarif per kilogram'
                            : 'Tarif per item',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatPrice(service['price']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          _hasItemService
              ? 'Catatan Pakaian'
              : 'Catatan Tambahan',
        ),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: _hasItemService
                ? 'Contoh: 2 kemeja, 1 jaket, 3 celana panjang.'
                : 'Tambahkan catatan untuk mitra laundry (opsional).',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
          ),
        ),
        if (_hasItemService)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Wajib diisi agar mitra mengetahui jenis dan jumlah pakaian.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderInformation() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.aquaTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Berat atau jumlah pakaian dan harga akhir akan ditentukan oleh mitra setelah proses penimbangan atau pemeriksaan pakaian.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.deepNavy,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Form Pemesanan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.aquaTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mitra Laundry',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.partner['business_name'] ?? 'Laundry',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildServicesSection(),
                  const SizedBox(height: 20),

                  _buildAddressSection(),
                  const SizedBox(height: 20),

                  _buildNotesSection(),
                  const SizedBox(height: 20),

                  _buildOrderInformation(),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ||
                              _isSelectingLocation
                          ? null
                          : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Buat Pesanan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
