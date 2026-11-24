
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

  final Set<String> _updatingOrderIds = {};

  int _selectedFilter = 0;

  bool? _isStoreOpen;
  bool _isLoadingStoreStatus = true;
  bool _isStoreStatusAvailable = true;

  bool _isLoadingOrders = true;
  String? _errorMessage;

  String? _partnerId;
  List<Map<String, dynamic>> _orders = [];

  final List<String> _filters = [
    'Semua',
    'Baru',
    'Perlu Dijemput',
    'Diproses',
    'Selesai',
  ];

  String? _nextStatus(String status) {
    switch (status) {
      case 'confirmed':
        return 'pickup';
      case 'pickup':
        return 'processing';
      case 'processing':
        return 'delivering';
      case 'delivering':
        return 'completed';
      default:
        return null;
    }
  }

  String _nextActionLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Mulai Penjemputan';
      case 'pickup':
        return 'Sedang Diproses';
      case 'processing':
        return 'Sedang Diantar';
      case 'delivering':
        return 'Selesaikan Pesanan';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadStoreStatus();
    await _loadOrders();
  }

  Future<void> _loadStoreStatus() async {
    try {
      final session = await _authService.getSession();

      if (session == null || session['id'] == null) {
        throw Exception('User session not found.');
      }

      final response = await _supabase
          .from('partners')
          .select('id, is_open')
          .eq('profile_id', session['id']!)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _partnerId = response?['id']?.toString();
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

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoadingOrders = true;
      _errorMessage = null;
    });

    try {
      if (_partnerId == null) {
        await _loadStoreStatus();
      }

      if (_partnerId == null) {
        throw Exception('Partner account not found.');
      }

      final response = await _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            status,
            created_at,
            customer_address,
            customer_address_detail,
            notes,
            subtotal,
            total_amount,
            profiles!orders_customer_id_fkey(full_name),
            order_items(
              service_name,
              quantity,
              unit_price,
              line_total
            )
          ''')
          .eq('partner_id', _partnerId!)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoadingOrders = false;
      });
    } catch (error) {
      debugPrint('Load Partner Orders Error: $error');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal memuat pesanan. Silakan coba lagi.';
        _isLoadingOrders = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    switch (_selectedFilter) {
      case 1:
        return _orders
            .where((order) => order['status'] == 'pending')
            .toList();

      case 2:
        return _orders
            .where((order) => order['status'] == 'confirmed')
            .toList();

      case 3:
        return _orders
            .where((order) => [
                  'pickup',
                  'processing',
                  'delivering',
                ].contains(order['status']))
            .toList();

      case 4:
        return _orders
            .where((order) => order['status'] == 'completed')
            .toList();

      default:
        return _orders;
    }
  }

  int _countOrders(List<String> statuses) {
    return _orders
        .where((order) => statuses.contains(order['status']))
        .length;
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
              border: Border.all(color: AppColors.border),
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
    required int count,
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
                  count.toString(),
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
                count: _countOrders(['pending']),
                icon: Icons.inbox_outlined,
              ),
              _buildSummaryCard(
                title: 'Perlu Dijemput',
                count: _countOrders(['confirmed']),
                icon: Icons.delivery_dining_outlined,
              ),
              _buildSummaryCard(
                title: 'Diproses',
                count: _countOrders([
                  'pickup',
                  'processing',
                  'delivering',
                ]),
                icon: Icons.local_laundry_service_outlined,
              ),
              _buildSummaryCard(
                title: 'Selesai',
                count: _countOrders(['completed']),
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
      onSelected: (_) {
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

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Perlu Dijemput';
      case 'pickup':
        return 'Sedang Dijemput';
      case 'processing':
        return 'Sedang Dicuci';
      case 'delivering':
        return 'Sedang Diantar';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.danger;
      case 'pending':
        return AppColors.starPromo;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(String? value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '-';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _updateOrderStatus({
    required String orderId,
    required String currentStatus,
    required String newStatus,
  }) async {
    if (_partnerId == null) return;

    final isRejecting = newStatus == 'rejected';

    if (isRejecting) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Tolak Pesanan?'),
            content: const Text(
              'Apakah kamu yakin ingin menolak pesanan ini?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Tolak'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;
    }

    if (_updatingOrderIds.contains(orderId)) return;

    setState(() {
      _updatingOrderIds.add(orderId);
    });

    try {
      final response = await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId)
          .eq('partner_id', _partnerId!)
          .eq('status', currentStatus)
          .select('id')
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        throw Exception('Order status has changed.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRejecting
                ? 'Pesanan berhasil ditolak.'
                : 'Status pesanan berhasil diperbarui.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      await _loadOrders();
    } catch (error) {
      debugPrint('Update Order Status Error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingOrderIds.remove(orderId);
        });
      }
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';
    final customer = order['profiles'] as Map<String, dynamic>?;
    final items = (order['order_items'] as List<dynamic>?) ?? [];

    final serviceNames = items
        .map((item) => item['service_name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .join(', ');

    final statusColor = _statusColor(status);
    final orderId = order['id'].toString();
    final isUpdating = _updatingOrderIds.contains(orderId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pesanan #${order['order_number'] ?? '-'}',
                style: const TextStyle(
                  color: AppColors.deepNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            customer?['full_name']?.toString() ?? 'Customer',
            style: const TextStyle(
              color: AppColors.deepNavy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order['customer_address']?.toString() ?? '-',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (serviceNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_laundry_service_outlined,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    serviceNames,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(order['created_at']?.toString()),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                'Rp ${order['total_amount'] ?? 0}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isUpdating
                        ? null
                        : () {
                            _updateOrderStatus(
                              orderId: orderId,
                              currentStatus: 'pending',
                              newStatus: 'rejected',
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tolak',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : () {
                            _updateOrderStatus(
                              orderId: orderId,
                              currentStatus: 'pending',
                              newStatus: 'confirmed',
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Terima',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],

          if (_nextStatus(status) != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () {
                        _updateOrderStatus(
                          orderId: orderId,
                          currentStatus: status,
                          newStatus: _nextStatus(status)!,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _nextActionLabel(status),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    final String title = _selectedFilter == 0
        ? 'Belum Ada Pesanan'
        : 'Belum Ada Pesanan ${_filters[_selectedFilter]}';

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
            const Text(
              'Pesanan yang masuk akan muncul di halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
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

  Widget _buildOrderList() {
    if (_isLoadingOrders) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: _buildEmptyState(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
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
                      child: _buildOrderList(),
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
