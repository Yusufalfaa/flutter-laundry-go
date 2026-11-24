
import 'package:flutter/material.dart';

import '../widgets/customer_bottom_nav.dart';
import 'customer_home_screen.dart';
import 'customer_search_screen.dart';
import 'customer_orders_screen.dart';
import 'customer_profile_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() =>
      _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;

  final ValueNotifier<String?> _searchServiceFilter =
      ValueNotifier<String?>(null);

  void _openSearchWithFilter(String serviceType) {
    _searchServiceFilter.value = serviceType;

    setState(() {
      _selectedIndex = 1;
    });
  }

  void _openOrders() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _openHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  late final List<Widget> _pages = [
    CustomerHomeScreen(
      onServiceSelected: _openSearchWithFilter,
      onViewAllOrders: _openOrders,
    ),
    CustomerSearchScreen(
      serviceFilter: _searchServiceFilter,
      onBackToHome: _openHome,
    ),
    const CustomerOrdersScreen(),
    const CustomerProfileScreen(),
  ];

  @override
  void dispose() {
    _searchServiceFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFB),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomerBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
