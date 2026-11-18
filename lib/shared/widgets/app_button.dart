/* Reusable button for LaundryGo.

Usage:
```dart
  AppButton(
    text: 'Masuk',
    onPressed: () {},
  )

  AppButton(
    text: 'Daftar',
    variant: AppButtonVariant.secondary,
    onPressed: () {},
  )
```

Variants:
 - primary: Teal background with white text.
 - secondary: White background with teal text and border.
*/ 

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppButtonVariant {
  primary,
  secondary,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.variant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? AppColors.primary
            : Colors.white,
        foregroundColor: isPrimary
            ? Colors.white
            : AppColors.primary,
        disabledBackgroundColor: isPrimary
            ? AppColors.primary.withValues(alpha: 0.5)
            : Colors.white,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: AppColors.primary),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isPrimary
                    ? Colors.white
                    : AppColors.primary,
              ),
            )
          : Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isPrimary
                    ? Colors.white
                    : AppColors.primary,
              ),
            ),
    );

    if (isExpanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
