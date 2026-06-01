import 'package:flutter/material.dart';
import 'package:school_management/utils/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? textColor;
  final Color? loadingColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.width,
    this.height,
    this.icon,
    this.isFullWidth = false,
    this.padding,
    this.borderRadius,
    this.textColor,
    this.loadingColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.primaryColor;
    final buttonHeight = height ?? 50;
    final buttonWidth = isFullWidth ? double.infinity : width;
    final buttonPadding = padding ?? const EdgeInsets.symmetric(vertical: 14);
    final buttonBorderRadius = borderRadius ?? 12.0;
    
    final Widget button;
    
    if (isOutlined) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? buttonColor,
          side: BorderSide(color: buttonColor, width: 1.5),
          padding: buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          minimumSize: Size(buttonWidth ?? 0, buttonHeight),
          maximumSize: Size(buttonWidth ?? double.infinity, buttonHeight),
        ),
        child: _buildChild(textColor ?? buttonColor),
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor ?? Colors.white,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          minimumSize: Size(buttonWidth ?? 0, buttonHeight),
          maximumSize: Size(buttonWidth ?? double.infinity, buttonHeight),
          elevation: 0,
          disabledBackgroundColor: buttonColor.withOpacity(0.6),
        ),
        child: _buildChild(textColor ?? Colors.white),
      );
    }
    
    if (buttonWidth == null && !isFullWidth) {
      return button;
    }
    
    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: button,
    );
  }

  Widget _buildChild(Color defaultColor) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            loadingColor ?? defaultColor,
          ),
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      );
    }
    
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}