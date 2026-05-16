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
        SizedBox(
          width: iconSize * 1.1,
          height: iconSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.home_work_rounded,
                size: iconSize,
                color: AppColors.kodiNavy,
              ),
              Positioned(
                right: -2,
                bottom: 0,
                child: Container(
                  width: iconSize * 0.42,
                  height: iconSize * 0.42,
                  decoration: BoxDecoration(
                    color: AppColors.kodiGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        'KSh',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: iconSize * 0.18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                style: TextStyle(color: AppColors.kodiNavy),
              ),
              TextSpan(
                text: 'Pay',
                style: TextStyle(color: AppColors.kodiGreen),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
