
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';

class PartnerServicesScreen extends StatefulWidget {
  const PartnerServicesScreen({super.key});

  @override
  State<PartnerServicesScreen> createState() =>
      _PartnerServicesScreenState();
}

class _PartnerServicesScreenState extends State<PartnerServicesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _services = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
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

      final partner = await _supabase
          .from('partners')
          .select('id')
          .eq('profile_id', session['id']!)
          .single();

      final response = await _supabase
          .from('services')
          .select('id, service_type, price, is_available')
          .eq('partner_id', partner['id']);

      final services = List<Map<String, dynamic>>.from(response);

      services.sort((a, b) {
        const order = {
          'by_weight': 0,
          'by_item': 1,
        };

        return (order[a['service_type']] ?? 99)
            .compareTo(order[b['service_type']] ?? 99);
      });

      if (!mounted) return;

      setState(() {
        _services = services;
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

  String _serviceName(String serviceType) {
    switch (serviceType) {
      case 'by_weight':
        return 'Laundry Kiloan';
      case 'by_item':
        return 'Laundry Satuan';
      default:
        return 'Layanan Laundry';
    }
  }

  String _serviceDescription(String serviceType) {
    switch (serviceType) {
      case 'by_weight':
        return 'Harga layanan per kilogram';
      case 'by_item':
        return 'Harga layanan per item';
      default:
        return '';
    }
  }

  String _priceUnit(String serviceType) {
    switch (serviceType) {
      case 'by_weight':
        return '/kg';
      case 'by_item':
        return '/item';
      default:
        return '';
    }
  }

  String _formatPrice(dynamic price) {
    final value = (price as num).toInt();
    final digits = value.toString();

    final formatted = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp$formatted';
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showEditPriceDialog(
    Map<String, dynamic> service,
  ) async {
    if (_isSaving) return;

    final newPrice = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return EditServicePriceDialog(
          serviceName: _serviceName(service['service_type']),
          currentPrice: (service['price'] as num).toInt(),
        );
      },
    );

    if (!mounted || newPrice == null) return;

    await _updatePrice(service, newPrice);
  }

  Future<void> _updatePrice(
    Map<String, dynamic> service,
    int newPrice,
  ) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _supabase
          .from('services')
          .update({'price': newPrice})
          .eq('id', service['id']);

      if (!mounted) return;

      setState(() {
        final index = _services.indexWhere(
          (item) => item['id'] == service['id'],
        );

        if (index != -1) {
          _services[index]['price'] = newPrice;
        }
      });

      _showMessage('Harga berhasil diperbarui.');
    } catch (error) {
      _showMessage(
        'Gagal memperbarui harga: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _toggleAvailability(
    Map<String, dynamic> service,
    bool value,
  ) async {
    if (_isSaving) return;

    final price = (service['price'] as num).toDouble();

    if (value && price <= 0) {
      _showMessage(
        'Atur harga layanan terlebih dahulu sebelum mengaktifkannya.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _supabase
          .from('services')
          .update({'is_available': value})
          .eq('id', service['id']);

      if (!mounted) return;

      setState(() {
        final index = _services.indexWhere(
          (item) => item['id'] == service['id'],
        );

        if (index != -1) {
          _services[index]['is_available'] = value;
        }
      });

      _showMessage(
        value
            ? 'Layanan berhasil diaktifkan.'
            : 'Layanan berhasil dinonaktifkan.',
      );
    } catch (error) {
      _showMessage(
        'Gagal mengubah status layanan: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildServiceCard(
    Map<String, dynamic> service,
  ) {
    final serviceType = service['service_type'] as String;
    final isAvailable = service['is_available'] as bool;
    final price = service['price'] as num;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.aquaTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  serviceType == 'by_weight'
                      ? Icons.scale_rounded
                      : Icons.checkroom_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _serviceName(serviceType),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _serviceDescription(serviceType),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAvailable ? 'AKTIF' : 'NONAKTIF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isAvailable
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Harga Layanan',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  price > 0
                      ? '${_formatPrice(price)} ${_priceUnit(serviceType)}'
                      : 'Belum diatur',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _showEditPriceDialog(service),
                icon: const Icon(
                  Icons.edit_rounded,
                  size: 16,
                ),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const Divider(
            height: 28,
            color: AppColors.border,
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ketersediaan Layanan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
              Switch(
                value: isAvailable,
                activeTrackColor: AppColors.primary,
                onChanged: _isSaving
                    ? null
                    : (value) =>
                        _toggleAvailability(service, value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadServices,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Layanan Saya',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Atur jenis layanan, harga, dan ketersediaan '
                'laundry tokomu.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 42,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal memuat layanan.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadServices,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              else if (_services.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      'Belum ada layanan yang tersedia.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ..._services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child: _buildServiceCard(service),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditServicePriceDialog extends StatefulWidget {
  final String serviceName;
  final int currentPrice;

  const EditServicePriceDialog({
    super.key,
    required this.serviceName,
    required this.currentPrice,
  });

  @override
  State<EditServicePriceDialog> createState() =>
      _EditServicePriceDialogState();
}

class _EditServicePriceDialogState
    extends State<EditServicePriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.currentPrice.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Ubah Harga Layanan',
        style: TextStyle(
          color: AppColors.deepNavy,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.serviceName,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Harga (Rupiah)',
              prefixText: 'Rp ',
              hintText: 'Masukkan harga',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Batal',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final value = int.tryParse(_controller.text);

            if (value == null || value <= 0) {
              return;
            }

            Navigator.pop(context, value);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
