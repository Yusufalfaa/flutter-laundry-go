
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:laundry_go/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() =>
      _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _partners = [];
  final Set<String> _selectedServices = {};

  Position? _currentPosition;

  bool _isLoading = true;
  bool _isRefreshingLocation = false;

  String? _errorMessage;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _getCurrentLocation();
    await _fetchPartners();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
          'Please enable it in app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _locationMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _currentPosition = null;
        _locationMessage = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isRefreshingLocation = true;
    });

    await _getCurrentLocation();

    if (!mounted) return;

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

      setState(() {
        _partners = (response as List)
            .map(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();

        _partners.sort(_comparePartners);
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
    if (_currentPosition == null) return null;

    final latitude = partner['latitude'];
    final longitude = partner['longitude'];

    if (latitude == null || longitude == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
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
    final searchQuery = _searchController.text.trim().toLowerCase();

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Detail ${partner['business_name']} akan segera tersedia.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.maybePop(context);
          },
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
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                ),
          tooltip: 'Refresh location',
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
    if (_locationMessage == null) {
      return Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            _currentPosition != null
                ? 'Menampilkan laundry terdekat dari lokasimu'
                : 'Lokasi belum tersedia',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.aquaTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_off_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lokasi tidak tersedia. '
              'Daftar laundry tetap ditampilkan tanpa jarak.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.deepNavy,
              ),
            ),
          ),
          TextButton(
            onPressed: _refreshLocation,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
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
