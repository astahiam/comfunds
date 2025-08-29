import 'package:flutter/material.dart';
import '../../utils/constants.dart';

enum ButtonVariant { filled, outlined, text }
enum ButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.textStyle,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _getButtonHeight(),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case ButtonVariant.filled:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: textColor ?? Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_getBorderRadius()),
            ),
            padding: _getPadding(),
          ),
          child: _buildButtonContent(),
        );
      
      case ButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primary,
            side: BorderSide(
              color: borderColor ?? AppColors.primary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_getBorderRadius()),
            ),
            padding: _getPadding(),
          ),
          child: _buildButtonContent(),
        );
      
      case ButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_getBorderRadius()),
            ),
            padding: _getPadding(),
          ),
          child: _buildButtonContent(),
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.filled 
              ? Colors.white 
              : (textColor ?? AppColors.primary),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: AppSizes.sm),
          Text(
            text,
            style: textStyle ?? _getDefaultTextStyle(),
          ),
        ],
      );
    }

    return Text(
      text,
      style: textStyle ?? _getDefaultTextStyle(),
    );
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppSizes.buttonHeightSmall;
      case ButtonSize.medium:
        return AppSizes.buttonHeightMedium;
      case ButtonSize.large:
        return AppSizes.buttonHeightLarge;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return AppSizes.radiusSm;
      case ButtonSize.medium:
        return AppSizes.radiusMd;
      case ButtonSize.large:
        return AppSizes.radiusLg;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.md,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.lg,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  TextStyle _getDefaultTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTextStyles.buttonSmall;
      case ButtonSize.medium:
        return AppTextStyles.buttonMedium;
      case ButtonSize.large:
        return AppTextStyles.buttonLarge;
    }
  }
}
