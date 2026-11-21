
import 'package:flutter/material.dart';

import 'package:laundry_go/core/constants/app_colors.dart';

// Link to next screen
import 'package:laundry_go/features/auth/screens/phone_auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    this.onPhonePressed,
    this.onGooglePressed,
    this.onPartnerPressed,
  });

  final VoidCallback? onPhonePressed;
  final VoidCallback? onGooglePressed;
  final VoidCallback? onPartnerPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aquaTint,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            final bubbleSize = screenWidth * 0.30;
            final panelTop = screenHeight * 0.43;

            return Stack(
              children: [
                // Decorative bubbles
                Positioned(
                  top: panelTop * 0.08,
                  left: -bubbleSize * 0.25,
                  child: _Bubble(
                    size: bubbleSize,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: panelTop * 0.32,
                  right: -bubbleSize * 0.20,
                  child: _Bubble(
                    size: bubbleSize,
                    color: AppColors.primaryBright,
                  ),
                ),
                Positioned(
                  top: panelTop * 0.65,
                  left: -bubbleSize * 0.22,
                  child: _Bubble(
                    size: bubbleSize,
                    color: AppColors.primaryBright,
                  ),
                ),
                Positioned(
                  top: panelTop * 0.78,
                  right: -bubbleSize * 0.22,
                  child: _Bubble(
                    size: bubbleSize,
                    color: Colors.white,
                  ),
                ),

                // Branding section
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  height: panelTop - 12,
                  child: Center(
                    child: Image.asset(
                      'assets/images/logos/laundrygo_brand_vertical.png',
                      width: screenWidth * 0.55,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Authentication panel
                Positioned(
                  top: panelTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masuk atau Daftar',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cari laundry terdekat dan pesan antar '
                            'jemput dalam beberapa ketukan.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                          const SizedBox(height: 20),

                          // Customer phone authentication
                          _WelcomeOptionButton(
                            label: 'Lanjutkan dengan Nomor HP',
                            icon: const Icon(
                              Icons.phone_iphone_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            onPressed: () => {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => const PhoneAuthScreen(
                                    role: 'customer',
                                  )))
                            }
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 20),

                          // Partner registration
                          Text(
                            'Punya usaha Laundry?',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _WelcomeOptionButton(
                            label: 'Punya usaha laundry?',
                            subtitle: 'Daftar/Masuk sebagai Mitra LaundryGo',
                            icon: const Icon(
                              Icons.storefront_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            backgroundColor: AppColors.aquaTint,
                            borderColor: AppColors.aquaTint,
                            onPressed: () => {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => const PhoneAuthScreen(
                                    role: 'partner',
                                  )))
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Decorative bubble
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.75),
        shape: BoxShape.circle,
      ),
    );
  }
}

// Reusable button within WelcomeScreen
class _WelcomeOptionButton extends StatelessWidget {
  const _WelcomeOptionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.subtitle,
    this.backgroundColor = Colors.white,
    this.borderColor = AppColors.border,
  });

  final String label;
  final String? subtitle;
  final Widget icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.deepNavy,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (subtitle != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

