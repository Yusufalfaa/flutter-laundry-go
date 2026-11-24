
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';

enum IncomePeriod {
  today,
  week,
  month,
}

class PartnerIncomeScreen extends StatefulWidget {
  const PartnerIncomeScreen({super.key});

  @override
  State<PartnerIncomeScreen> createState() =>
      _PartnerIncomeScreenState();
}

class _PartnerIncomeScreenState extends State<PartnerIncomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  IncomePeriod _selectedPeriod = IncomePeriod.week;

  bool _isLoading = true;
  String? _errorMessage;

  String? _partnerId;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _recentOrders = [];

  double _totalIncome = 0;

  @override
  void initState() {
    super.initState();
    _loadIncome();
  }

  Future<void> _loadIncome() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _authService.getSession();

      if (session == null) {
        throw Exception('User session not found.');
      }

      final partner = await _supabase
          .from('partners')
          .select('id')
          .eq('profile_id', session['id']!)
          .single();

      _partnerId = partner['id'] as String;

      final now = DateTime.now();
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 29));

      final response = await _supabase
          .from('orders')
          .select(
            'id, order_number, subtotal, completed_at',
          )
          .eq('partner_id', _partnerId!)
          .eq('status', 'completed')
          .gte(
            'completed_at',
            startDate.toUtc().toIso8601String(),
          )
          .order('completed_at', ascending: false);

      final recentResponse = await _supabase
          .from('orders')
          .select(
            'id, order_number, subtotal, completed_at',
          )
          .eq('partner_id', _partnerId!)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .limit(3);

      if (!mounted) return;

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _recentOrders =
            List<Map<String, dynamic>>.from(recentResponse);

        _calculateTotalIncome();
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load Income Error: $error');

      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateTotalIncome() {
    final now = DateTime.now();

    DateTime startDate;

    switch (_selectedPeriod) {
      case IncomePeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case IncomePeriod.week:
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        break;
      case IncomePeriod.month:
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        break;
    }

    _totalIncome = 0;

    for (final order in _orders) {
      final completedAt =
          DateTime.parse(order['completed_at']).toLocal();

      if (!completedAt.isBefore(startDate)) {
        _totalIncome +=
            (order['subtotal'] as num?)?.toDouble() ?? 0;
      }
    }
  }

  void _changePeriod(IncomePeriod period) {
    setState(() {
      _selectedPeriod = period;
      _calculateTotalIncome();
    });
  }

  String _formatCurrency(double amount) {
    final value = amount.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);

      final remaining = value.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'Rp $buffer';
  }

  String _formatDate(String? value) {
    if (value == null) return '-';

    final date = DateTime.parse(value).toLocal();

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'Mei', 'Jun', 'Jul', 'Agu',
      'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<double> _getChartValues() {
    final now = DateTime.now();
    final values = <double>[];

    if (_selectedPeriod == IncomePeriod.today) {
      for (int hour = 0; hour < 24; hour += 4) {
        double total = 0;

        for (final order in _orders) {
          final date =
              DateTime.parse(order['completed_at']).toLocal();

          if (date.year == now.year &&
              date.month == now.month &&
              date.day == now.day &&
              date.hour >= hour &&
              date.hour < hour + 4) {
            total += (order['subtotal'] as num?)?.toDouble() ?? 0;
          }
        }

        values.add(total);
      }
    } else if (_selectedPeriod == IncomePeriod.week) {
      for (int day = 6; day >= 0; day--) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: day));

        double total = 0;

        for (final order in _orders) {
          final completedAt =
              DateTime.parse(order['completed_at']).toLocal();

          if (completedAt.year == date.year &&
              completedAt.month == date.month &&
              completedAt.day == date.day) {
            total +=
                (order['subtotal'] as num?)?.toDouble() ?? 0;
          }
        }

        values.add(total);
      }
    } else {
      for (int period = 5; period >= 0; period--) {
        final endDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: period * 5));

        final startDate =
            endDate.subtract(const Duration(days: 4));

        double total = 0;

        for (final order in _orders) {
          final completedAt =
              DateTime.parse(order['completed_at']).toLocal();

          final isAfterStart =
              !completedAt.isBefore(startDate);

          final isBeforeEnd =
              !completedAt.isAfter(
                endDate.add(const Duration(days: 1)),
              );

          if (isAfterStart && isBeforeEnd) {
            total +=
                (order['subtotal'] as num?)?.toDouble() ?? 0;
          }
        }

        values.add(total);
      }
    }

    return values;
  }

  List<String> _getChartLabels() {
    final now = DateTime.now();

    if (_selectedPeriod == IncomePeriod.today) {
      return ['00', '04', '08', '12', '16', '20'];
    }

    if (_selectedPeriod == IncomePeriod.week) {
      const days = [
        'Min', 'Sen', 'Sel', 'Rab',
        'Kam', 'Jum', 'Sab',
      ];

      return List.generate(7, (index) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: 6 - index));

        return days[date.weekday % 7];
      });
    }

    return ['1-5', '6-10', '11-15', '16-20', '21-25', '26-30'];
  }

  Widget _buildPeriodButton(
    String label,
    IncomePeriod period,
  ) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changePeriod(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final values = _getChartValues();
    final labels = _getChartLabels();

    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Pendapatan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 155,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                final height = maxValue == 0
                    ? 4.0
                    : (values[index] / maxValue) * 105;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height.clamp(4.0, 105.0),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBright,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          labels[index],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rp 0',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fitur saldo belum tersedia',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Tarik Tunai'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Uang Masuk',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentOrders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Belum ada pendapatan.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ..._recentOrders.map((order) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.aquaTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pesanan #${order['order_number']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(order['completed_at']),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${_formatCurrency((order['subtotal'] as num?)?.toDouble() ?? 0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(color: AppColors.border),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Halaman riwayat pendapatan akan dibuat berikutnya.',
                    ),
                  ),
                );
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
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
            const SizedBox(height: 12),
            const Text(
              'Gagal Memuat Pendapatan',
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
              onPressed: _loadIncome,
              child: const Text('Coba Lagi'),
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Pendapatan',
          style: TextStyle(
            color: AppColors.deepNavy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadIncome,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _errorMessage != null
              ? _buildErrorPage()
              : RefreshIndicator(
                  onRefresh: _loadIncome,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Pendapatan',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatCurrency(_totalIncome),
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                _buildPeriodButton(
                                  'Hari Ini',
                                  IncomePeriod.today,
                                ),
                                const SizedBox(width: 8),
                                _buildPeriodButton(
                                  '7 Hari',
                                  IncomePeriod.week,
                                ),
                                const SizedBox(width: 8),
                                _buildPeriodButton(
                                  '30 Hari',
                                  IncomePeriod.month,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildChart(),
                      const SizedBox(height: 16),
                      _buildBalanceCard(),
                      const SizedBox(height: 16),
                      _buildRecentOrders(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
