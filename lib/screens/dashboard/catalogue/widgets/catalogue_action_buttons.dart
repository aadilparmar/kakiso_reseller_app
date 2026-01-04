import 'package:flutter/material.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';

class CatalogueActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? bgColor;
  final bool outlined;
  final bool isTarget;
  final bool isDimmed;
  final Animation<double>? pulseAnimation;

  const CatalogueActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.bgColor,
    this.outlined = false,
    this.isTarget = false,
    this.isDimmed = false,
    this.pulseAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color effectiveColor = color ?? accentColor;
    Color effectiveBg = bgColor ?? Colors.white;

    if (isTarget) {
      effectiveColor = Colors.white;
      effectiveBg = accentColor;
    } else if (isDimmed) {
      effectiveColor = effectiveColor.withOpacity(0.3);
      effectiveBg = effectiveBg.withOpacity(0.5);
    }

    Widget button = SizedBox(
      height: 34,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: effectiveColor.withOpacity(0.5)),
                backgroundColor: isTarget ? effectiveBg : null,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: Icon(
                icon,
                size: UIConstants.iconSize,
                color: effectiveColor,
              ),
              label: AutoTranslate(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                ),
              ),
            )
          : TextButton.icon(
              onPressed: onTap,
              style: TextButton.styleFrom(
                backgroundColor: effectiveBg,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: Icon(
                icon,
                size: UIConstants.iconSize,
                color: effectiveColor,
              ),
              label: AutoTranslate(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                ),
              ),
            ),
    );

    if (isTarget && pulseAnimation != null) {
      return ScaleTransition(scale: pulseAnimation!, child: button);
    }

    return button;
  }
}

class SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isDimmed;

  const SocialIconButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.isDimmed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDimmed ? 0.3 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
