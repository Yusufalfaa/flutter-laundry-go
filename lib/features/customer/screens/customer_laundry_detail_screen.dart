
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/customer/screens/customer_order_form_screen.dart';

class CustomerLaundryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> partner;
  final double? distanceInMeters;

  const CustomerLaundryDetailScreen({
    super.key,
    required this.partner,
    this.distanceInMeters,
  });

  @override
  State<CustomerLaundryDetailScreen> createState() =>
      _CustomerLaundryDetailScreenState();
}

class _CustomerLaundryDetailScreenState
    extends State<CustomerLaundryDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _services = [];
  final List<String> _selectedServiceIds = [];

  Future<void> _loadServices() async {
    try {
      final response = await _supabase
          .from('services')
          .select('id, service_type, price, is_available')
          .eq('partner_id', widget.partner['id'])
          .eq('is_available', true)
          .order('service_type');

      if (!mounted) return;

      setState(() {
        _services = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load Laundry Services Error: $error');

      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleService(String serviceId) {
    setState(() {
      if (_selectedServiceIds.contains(serviceId)) {
        _selectedServiceIds.remove(serviceId);
      } else {
        _selectedServiceIds.add(serviceId);
      }
    });
  }

  void _continueToOrder() {
    if (_selectedServiceIds.isEmpty) return;

    final selectedServices = _services
        .where(
          (service) =>
              _selectedServiceIds.contains(service['id'].toString()),
        )
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerOrderFormScreen(
          partner: widget.partner,
          selectedServices: selectedServices,
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;
    final formatted = amount.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < formatted.length; i++) {
      buffer.write(formatted[i]);

      final remaining = formatted.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'Rp $buffer';
  }

  String _getServiceName(String serviceType) {
    switch (serviceType) {
      case 'by_weight':
        return 'Laundry Kiloan';
      case 'by_item':
        return 'Laundry Satuan';
      default:
        return 'Layanan Laundry';
    }
  }

  String _getServiceUnit(String serviceType) {
    switch (serviceType) {
      case 'by_weight':
        return '/ kg';
      case 'by_item':
        return '/ item';
      default:
        return '';
    }
  }

  String? _formatDistance() {
    final distance = widget.distanceInMeters;

    if (distance == null) return null;

    if (distance < 1000) {
      return '${distance.round()} m';
    }

    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildHeader() {
    final isOpen = widget.partner['is_open'] == true;
    final distance = _formatDistance();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.partner['business_name'] ?? 'Laundry',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOpen
                      ? const Color(0xFFE6F5EC)
                      : const Color(0xFFFCE9E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen ? 'OPEN' : 'CLOSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isOpen
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (distance != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.near_me_outlined,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Text(
                  distance,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  [
                    widget.partner['address'],
                    widget.partner['address_detail'],
                  ].where((value) =>
                      value != null &&
                      value.toString().trim().isNotEmpty).join(', '),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final serviceId = service['id'].toString();
    final serviceType = service['service_type'].toString();
    final isSelected = _selectedServiceIds.contains(serviceId);

    return GestureDetector(
      onTap: () => _toggleService(serviceId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 1.7 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.aquaTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                serviceType == 'by_weight'
                    ? Icons.scale_outlined
                    : Icons.checkroom_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getServiceName(serviceType),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_formatCurrency(service['price'])} ${_getServiceUnit(serviceType)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 23,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServices() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: _loadServices,
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    if (_services.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text(
          'Belum ada layanan yang tersedia.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: _services.map((service) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildServiceCard(service),
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.deepNavy,
          ),
        ),
        title: const Text(
          'Detail Laundry',
          style: TextStyle(
            color: AppColors.deepNavy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          const Text(
            'Pilih Layanan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kamu bisa memilih lebih dari satu layanan.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildServices(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedServiceIds.isEmpty
                  ? null
                  : _continueToOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lanjutkan Pemesanan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
