import 'package:flutter/material.dart';
import '../utils/constants.dart';

class KodiPayLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const KodiPayLogo({
    super.key,
    this.iconSize = 40,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.home_work_rounded,
          size: iconSize,
          color: AppColors.kodiBlue,
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            children: const [
              TextSpan(
                text: 'Kodi',
                style: TextStyle(color: AppColors.kodiBlue),
              ),
              TextSpan(
                text: 'Pay',
                style: TextStyle(color: AppColors.kodiOrange),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
