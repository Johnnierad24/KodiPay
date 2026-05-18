import 'package:flutter/material.dart';
import '../utils/constants.dart';

class KodiPayLogo extends StatelessWidget {
  static const String assetPath = 'assets/images/kodipay_logo.png';

  final double iconSize;
  final double fontSize;
  final bool showSlogan;
  final bool vertical;

  const KodiPayLogo({
    super.key,
    this.iconSize = 40,
    this.fontSize = 24,
    this.showSlogan = false,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final assetLogo = _OfficialLogoAsset(
      width: vertical ? iconSize * 2.9 : iconSize * 4.2,
      fallback: _FallbackLogo(
        iconSize: iconSize,
        fontSize: fontSize,
        showSlogan: showSlogan,
        vertical: vertical,
      ),
    );

    return assetLogo;
  }
}

class _OfficialLogoAsset extends StatelessWidget {
  final double width;
  final Widget fallback;

  const _OfficialLogoAsset({
    required this.width,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      KodiPayLogo.assetPath,
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'KodiPay logo. Pay Rent. Stay Worry-Free.',
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showSlogan;
  final bool vertical;

  const _FallbackLogo({
    required this.iconSize,
    required this.fontSize,
    required this.showSlogan,
    required this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _KodiPayMark(size: iconSize),
          const SizedBox(height: 10),
          _LogoText(fontSize: fontSize),
          if (showSlogan) ...[
            const SizedBox(height: 10),
            _Slogan(fontSize: fontSize * 0.26),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _KodiPayMark(size: iconSize),
        const SizedBox(width: 8),
        _LogoText(fontSize: fontSize),
      ],
    );
  }
}

class _KodiPayMark extends StatelessWidget {
  final double size;

  const _KodiPayMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.35,
      height: size,
      child: CustomPaint(painter: _KodiPayMarkPainter()),
    );
  }
}

class _LogoText extends StatelessWidget {
  final double fontSize;

  const _LogoText({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'Poppins',
          height: 0.95,
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
    );
  }
}

class _Slogan extends StatelessWidget {
  final double fontSize;

  const _Slogan({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.kodiGreen,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Pay Rent. Stay Worry-Free.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.kodiNavy,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.kodiGreen,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _KodiPayMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 180;
    final scaleY = size.height / 140;
    canvas.scale(scaleX, scaleY);

    final navy = Paint()
      ..color = AppColors.kodiNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final green = Paint()
      ..color = AppColors.kodiGreen
      ..style = PaintingStyle.fill;

    final orange = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFC928), AppColors.kodiOrange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(0, 0, 180, 140));

    final roof = Path()
      ..moveTo(45, 65)
      ..lineTo(90, 25)
      ..lineTo(139, 65);
    canvas.drawPath(roof, navy);

    final chimney = Paint()
      ..color = AppColors.kodiNavy
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(58, 35, 15, 35), const Radius.circular(3)),
      chimney,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(56, 68, 16, 50), const Radius.circular(2)),
      chimney,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(126, 68, 16, 42), const Radius.circular(2)),
      chimney,
    );

    for (final rect in const [
      Rect.fromLTWH(82, 62, 10, 10),
      Rect.fromLTWH(98, 62, 10, 10),
      Rect.fromLTWH(82, 78, 10, 10),
      Rect.fromLTWH(98, 78, 10, 10),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        green,
      );
    }

    final greenSwoosh = Paint()
      ..color = AppColors.kodiGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final greenPath = Path()
      ..moveTo(28, 93)
      ..cubicTo(42, 123, 93, 128, 121, 112);
    canvas.drawPath(greenPath, greenSwoosh);

    final orangeSwoosh = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.kodiOrange, Color(0xFFFFC928)],
      ).createShader(const Rect.fromLTWH(40, 70, 130, 60))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final orangePath = Path()
      ..moveTo(105, 116)
      ..cubicTo(138, 105, 164, 78, 151, 62);
    canvas.drawPath(orangePath, orangeSwoosh);

    canvas.drawCircle(const Offset(104, 93), 22, orange);
    canvas.drawCircle(
      const Offset(104, 93),
      18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFDD55).withValues(alpha: 0.65),
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'KSh',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(104 - textPainter.width / 2, 93 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
