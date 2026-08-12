import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// The logo shown at the top of screens.
/// - Default: the wide wordmark `assets/images/logo.png` (used in-app).
/// - `useAppIcon: true`: the square `assets/images/app_icon.png` (used on login).
/// Falls back to a drawn wordmark if the image file is missing.
class FinanceLogo extends StatelessWidget {
  const FinanceLogo({
    super.key,
    this.size = 26,
    this.useAppIcon = true,
    this.adaptToDark = true,
  });
  final double size;
  final bool useAppIcon;

  /// When true (default) and the app is in dark mode, the wordmark switches to
  /// `app_icon_dark_mode.png`. The login screen sets this false to stay fixed.
  final bool adaptToDark;

  @override
  Widget build(BuildContext context) {
    if (useAppIcon) {
      final isDark = ThemeController.instance.isDark;
      final asset = (adaptToDark && isDark)
          ? 'assets/images/app_icon_dark_mode.png'
          : 'assets/images/app_icon.png';
      // Show the whole image (it's a wide wordmark), not cropped to a square.
      return Image.asset(
        asset,
        height: size + 54,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _wordmark(),
      );
    }
    return Image.asset(
      'assets/images/logo.png',
      height: size + 16,
      errorBuilder: (context, error, stackTrace) => _wordmark(),
    );
  }

  Widget _wordmark() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: size + 6,
          height: size + 6,
          decoration: BoxDecoration(
            color: AppColors.textDark,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text('F',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: size,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text('Finance',
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        Text('+',
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
      ],
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      // The card is always light. Force a light theme context inside it so all
      // text AND text fields stay dark/readable, even when the app is in dark
      // mode (where the surrounding theme uses light-colored text).
      child: Theme(
        data: AppTheme.light,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.textDark),
          child: IconTheme.merge(
            data: const IconThemeData(color: AppColors.textDark),
            child: child,
          ),
        ),
      ),
    );
  }
}