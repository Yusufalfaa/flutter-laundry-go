
import 'package:flutter/material.dart';
import 'package:laundry_go/core/constants/app_colors.dart';

class PartnerBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const PartnerBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color itemColor = isSelected
        ? AppColors.primary
        : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onItemSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: itemColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: itemColor,
                  fontSize: 11,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Pesanan',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.local_laundry_service_outlined,
              activeIcon: Icons.local_laundry_service_rounded,
              label: 'Layanan',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet_rounded,
              label: 'Pendapatan',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront_rounded,
              label: 'Toko',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }
}
