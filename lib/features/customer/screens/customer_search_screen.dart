
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:laundry_go/features/auth/services/auth_service.dart';
import 'package:laundry_go/features/customer/screens/customer_laundry_detail_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  final ValueNotifier<String?> serviceFilter;
  final VoidCallback onBackToHome;

  const CustomerSearchScreen({
    super.key,
    required this.serviceFilter,
    required this.onBackToHome,
  });

  @override
  State<CustomerSearchScreen> createState() =>
      _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _partners = [];
  final Set<String> _selectedServices = {};

  double? _customerLatitude;
  double? _customerLongitude;
  String? _customerAddress;

  bool _isLoading = true;
  bool _isRefreshingLocation = false;

  String? _errorMessage;

  bool get _hasDefaultAddress {
    return _customerAddress != null &&
        _customerAddress!.trim().isNotEmpty &&
        _customerLatitude != null &&
        _customerLongitude != null;
  }

  @override
  void initState() {
    super.initState();

    widget.serviceFilter.addListener(
      _handleServiceFilterChanged,
    );

    final initialFilter = widget.serviceFilter.value;

    if (initialFilter != null) {
      _selectedServices.add(initialFilter);
    }

    _initializeScreen();
  }

  @override
  void dispose() {
    widget.serviceFilter.removeListener(
      _handleServiceFilterChanged,
    );

    _searchController.dispose();
    super.dispose();
  }

  void _handleServiceFilterChanged() {
    final service = widget.serviceFilter.value;

    setState(() {
      _selectedServices.clear();

      if (service != null) {
        _selectedServices.add(service);
      }
    });
  }

  Future<void> _initializeScreen() async {
    await _loadDefaultAddress();
    await _fetchPartners();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final session = await _authService.getSession();

      if (session == null) {
        throw Exception('Customer session not found.');
      }

      final profile = await _supabase
          .from('profiles')
          .select('address, latitude, longitude')
          .eq('id', session['id']!)
          .single();

      if (!mounted) return;

      setState(() {
        _customerAddress = profile['address'] as String?;
        _customerLatitude =
            (profile['latitude'] as num?)?.toDouble();
        _customerLongitude =
            (profile['longitude'] as num?)?.toDouble();
      });
    } catch (error) {
      debugPrint('Load default address error: $error');

      if (!mounted) return;

      setState(() {
        _customerAddress = null;
        _customerLatitude = null;
        _customerLongitude = null;
      });
    }
  }

  Future<void> _refreshLocation() async {
    if (_isRefreshingLocation) return;

    setState(() {
      _isRefreshingLocation = true;
    });

    await _loadDefaultAddress();

    if (!mounted) return;

    _partners.sort(_comparePartners);

    setState(() {
      _isRefreshingLocation = false;
    });
  }

  Future<void> _fetchPartners() async {
    try {
      final response = await _supabase
          .from('partners')
          .select(
            'id, business_name, address, latitude, longitude, '
            'is_open, status, '
            'services(service_type, is_available)',
          )
          .eq('status', 'approved');

      if (!mounted) return;

      final partners = (response as List)
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      partners.sort(_comparePartners);

      setState(() {
        _partners = partners;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load laundry partners.';
      });

      debugPrint('Fetch partners error: $error');
    }
  }

  double? _getDistance(Map<String, dynamic> partner) {
    if (!_hasDefaultAddress) return null;

    final latitude = partner['latitude'];
    final longitude = partner['longitude'];

    if (latitude == null || longitude == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      _customerLatitude!,
      _customerLongitude!,
      (latitude as num).toDouble(),
      (longitude as num).toDouble(),
    );
  }

  int _comparePartners(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final firstOpen = first['is_open'] == true;
    final secondOpen = second['is_open'] == true;

    if (firstOpen != secondOpen) {
      return firstOpen ? -1 : 1;
    }

    final firstDistance = _getDistance(first);
    final secondDistance = _getDistance(second);

    if (firstDistance == null && secondDistance == null) {
      return 0;
    }

    if (firstDistance == null) return 1;
    if (secondDistance == null) return -1;

    return firstDistance.compareTo(secondDistance);
  }

  String _formatDistance(double? distance) {
    if (distance == null) return 'Jarak tidak tersedia';

    if (distance < 1000) {
      return '${distance.round()} m';
    }

    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  List<String> _getAvailableServices(
    Map<String, dynamic> partner,
  ) {
    final services = partner['services'] as List? ?? [];

    return services
        .where((service) => service['is_available'] == true)
        .map<String>((service) {
          return service['service_type'].toString();
        })
        .toList();
  }

  List<Map<String, dynamic>> get _filteredPartners {
    final searchQuery =
        _searchController.text.trim().toLowerCase();

    final filtered = _partners.where((partner) {
      final businessName =
          partner['business_name'].toString().toLowerCase();

      if (!businessName.contains(searchQuery)) {
        return false;
      }

      final availableServices = _getAvailableServices(partner);

      if (_selectedServices.isEmpty) {
        return true;
      }

      return _selectedServices.any(
        (service) => availableServices.contains(service),
      );
    }).toList();

    filtered.sort(_comparePartners);

    return filtered;
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  void _showPartnerDetails(Map<String, dynamic> partner) {
    final distance = _getDistance(partner);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerLaundryDetailScreen(
          partner: partner,
          distanceInMeters: distance,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onBackToHome,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.deepNavy,
          ),
        ),
        const Expanded(
          child: Text(
            'Laundry Terdekat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.deepNavy,
            ),
          ),
        ),
        IconButton(
          onPressed: _isRefreshingLocation
              ? null
              : _refreshLocation,
          icon: _isRefreshingLocation
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
          tooltip: 'Refresh default address',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Cari nama laundry...',
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceFilters() {
    return Wrap(
      spacing: 10,
      children: [
        _buildFilterChip(
          label: 'Kiloan',
          value: 'by_weight',
        ),
        _buildFilterChip(
          label: 'Satuan',
          value: 'by_item',
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
  }) {
    final isSelected = _selectedServices.contains(value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleService(value),
      showCheckmark: false,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.aquaTint,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : AppColors.border,
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primary
            : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildLocationInfo() {
    if (!_hasDefaultAddress) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.aquaTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_off_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Alamat belum diatur',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.deepNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: _refreshLocation,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_rounded,
          color: AppColors.primary,
          size: 17,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menggunakan alamat default',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _customerAddress!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _refreshLocation,
          icon: const Icon(
            Icons.refresh_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          tooltip: 'Refresh address',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    final isOpen = partner['is_open'] == true;
    final services = _getAvailableServices(partner);
    final distance = _getDistance(partner);

    return Opacity(
      opacity: isOpen ? 1 : 0.6,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isOpen
              ? () => _showPartnerDetails(partner)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        partner['business_name'] ?? 'Laundry',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDistance(distance),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Layanan tersedia',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 7),
                if (services.isEmpty)
                  const Text(
                    'Belum ada layanan tersedia',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: services.map((service) {
                      final label = service == 'by_weight'
                          ? 'Kiloan'
                          : 'Satuan';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.aquaTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerList() {
    final partners = _filteredPartners;

    if (partners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 55),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.local_laundry_service_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Laundry tidak ditemukan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Coba ubah pencarian atau filter layanan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: partners.map((partner) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPartnerCard(partner),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _buildHeader(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 42,
                                color: AppColors.danger,
                              ),
                              const SizedBox(height: 12),
                              Text(_errorMessage!),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  _fetchPartners();
                                },
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _buildSearchBar(),
                              const SizedBox(height: 16),
                              const Text(
                                'Filter Layanan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildServiceFilters(),
                              const SizedBox(height: 12),
                              _buildLocationInfo(),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Laundry di Sekitarmu',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_filteredPartners.length} laundry',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildPartnerList(),
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
