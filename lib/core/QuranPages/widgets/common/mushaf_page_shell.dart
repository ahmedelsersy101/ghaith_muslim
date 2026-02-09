import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/color_utils.dart';
import '../../../../../helpers/constants.dart';
import '../../../../../helpers/hive_helper.dart';

class MushafPageShell extends StatelessWidget {
  final Widget child;
  final bool isEvenPage;
  final Size screenSize;

  const MushafPageShell({
    super.key,
    required this.child,
    required this.isEvenPage,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final themeIndex = getValue("quranPageolorsIndex");
    final base = softOffWhites[themeIndex];
    final primary = darkWarmBrowns[themeIndex];
    final secondary = secondaryColors[themeIndex];
    final bool darkBase = base.computeLuminance() < 0.45;

    final paperLight = ColorUtils.blendColor(base, const Color(0xFFFFF7E6), darkBase ? 0.75 : 0.55);
    final paperMid = ColorUtils.blendColor(base, const Color(0xFFF0E0C0), darkBase ? 0.55 : 0.35);

    final borderTarget = darkBase ? const Color(0xFFE7C99B) : const Color(0xFF5D3E1F);
    final accentTarget = darkBase ? const Color(0xFFF0D7A8) : const Color(0xFF8B5E34);
    final border = ColorUtils.blendColor(primary, borderTarget, darkBase ? 0.55 : 0.25);
    final accent = ColorUtils.blendColor(secondary, accentTarget, darkBase ? 0.5 : 0.25);

    final double frameInset = (screenSize.shortestSide * 0.035).clamp(12.0, 22.0).toDouble();
    final double contentInset = (screenSize.shortestSide * 0.025).clamp(8.0, 14.0).toDouble();
    final double innerBorderInset = frameInset * 0.72;
    final double borderWidth =
        (screenSize.shortestSide * 0.0032).clamp(1.2, 2.6).toDouble() * (darkBase ? 1.08 : 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [paperLight, paperMid, paperLight],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(darkBase ? .18 : .12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(darkBase ? .12 : .08),
              blurRadius: 12,
              offset: isEvenPage ? const Offset(-6, 0) : const Offset(6, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: CustomPaint(
            foregroundPainter: MushafFramePainter(
              lightGray: border,
              deepBurgundyRed: accent,
              borderWidth: borderWidth,
              innerInset: innerBorderInset,
              cornerRadius: (screenSize.shortestSide * 0.03).clamp(10.0, 20.0).toDouble(),
            ),
            child: Padding(
              padding: EdgeInsets.all(frameInset),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(contentInset),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MushafFramePainter extends CustomPainter {
  MushafFramePainter({
    required this.lightGray,
    required this.deepBurgundyRed,
    required this.borderWidth,
    required this.innerInset,
    required this.cornerRadius,
  });

  final Color lightGray;
  final Color deepBurgundyRed;
  final double borderWidth;
  final double innerInset;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect outerRect = Offset.zero & size;
    final RRect outer = RRect.fromRectAndRadius(
      outerRect,
      Radius.circular(cornerRadius),
    );
    final Rect innerRect = Rect.fromLTWH(
      innerInset,
      innerInset,
      size.width - innerInset * 2,
      size.height - innerInset * 2,
    );
    final RRect inner = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(cornerRadius * 0.85),
    );

    final Paint borderPaint = Paint()
      ..color = lightGray.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final Paint innerPaint = Paint()
      ..color = lightGray.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 0.8;

    canvas.drawRRect(outer, borderPaint);
    canvas.drawRRect(inner, innerPaint);

    final Paint ornamentPaint = Paint()
      ..color = deepBurgundyRed.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 0.8;

    final Paint dotPaint = Paint()
      ..color = deepBurgundyRed.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final double cornerSize = innerInset * 0.9;

    void drawCorner(Canvas canvas) {
      final Path path = Path();
      path.moveTo(0, cornerSize * 0.6);
      path.quadraticBezierTo(0, 0, cornerSize * 0.6, 0);
      path.quadraticBezierTo(cornerSize, 0, cornerSize, cornerSize * 0.45);
      canvas.drawPath(path, ornamentPaint);

      final Path tail = Path();
      tail.moveTo(0, cornerSize * 0.85);
      tail.lineTo(cornerSize * 0.25, cornerSize);
      canvas.drawPath(tail, ornamentPaint);

      canvas.drawCircle(
        Offset(cornerSize * 0.68, cornerSize * 0.68),
        cornerSize * 0.05,
        dotPaint,
      );
      canvas.drawCircle(
        Offset(cornerSize * 0.42, cornerSize * 0.3),
        cornerSize * 0.035,
        dotPaint,
      );
    }

    canvas.save();
    canvas.translate(innerRect.left, innerRect.top);
    drawCorner(canvas);
    canvas.restore();

    canvas.save();
    canvas.translate(innerRect.right, innerRect.top);
    canvas.scale(-1, 1);
    drawCorner(canvas);
    canvas.restore();

    canvas.save();
    canvas.translate(innerRect.left, innerRect.bottom);
    canvas.scale(1, -1);
    drawCorner(canvas);
    canvas.restore();

    canvas.save();
    canvas.translate(innerRect.right, innerRect.bottom);
    canvas.scale(-1, -1);
    drawCorner(canvas);
    canvas.restore();

    final Paint midPaint = Paint()
      ..color = deepBurgundyRed.withOpacity(0.7)
      ..strokeWidth = borderWidth;

    final double midWidth = innerRect.width * 0.18;
    final double midY = innerRect.top - borderWidth * 0.5;
    canvas.drawLine(
      Offset(innerRect.center.dx - midWidth / 2, midY),
      Offset(innerRect.center.dx + midWidth / 2, midY),
      midPaint,
    );

    final double bottomY = innerRect.bottom + borderWidth * 0.5;
    canvas.drawLine(
      Offset(innerRect.center.dx - midWidth / 2, bottomY),
      Offset(innerRect.center.dx + midWidth / 2, bottomY),
      midPaint,
    );
  }

  @override
  bool shouldRepaint(covariant MushafFramePainter oldDelegate) {
    return oldDelegate.lightGray != lightGray ||
        oldDelegate.deepBurgundyRed != deepBurgundyRed ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.innerInset != innerInset ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}
