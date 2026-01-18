import 'package:app/ui/bottle_note_logo_path.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../main.dart';
import 'dart:math';

class LoadingWidget extends StatelessWidget {
  final bool isLoading;
  final Color waveColor;
  final Color bottleColor;
  final bool isBlur;

  const LoadingWidget({
    super.key,
    required this.isLoading,
    required this.waveColor,
    required this.bottleColor,
    this.isBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isLoading ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color:
              isBlur ? bottleColor.withValues(alpha: 0.2) : Colors.transparent,
        ),
        child: BackdropFilter(
          filter: isBlur
              ? ImageFilter.blur(sigmaX: 3, sigmaY: 3)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: WaveFillBox(
                width: 120,
                height: 171,
                waveColor: waveColor,
                bottleColor: bottleColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WaveFillBox extends StatefulWidget {
  final double width;
  final double height;
  final Color? waveColor;
  final Color? bottleColor;
  const WaveFillBox({
    super.key,
    this.width = 120,
    this.height = 171,
    this.waveColor,
    this.bottleColor,
  });

  @override
  State<WaveFillBox> createState() => _WaveFillBoxState();
}

class _WaveFillBoxState extends State<WaveFillBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<BottleNoteColors>()!;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _WaveFillPainter(
              animationValue: _controller.value,
              waveColor: widget.waveColor ?? colors.subCoral,
              bottleColor: widget.bottleColor ?? colors.bgGray,
            ),
          );
        },
      ),
    );
  }
}

class _WaveFillPainter extends CustomPainter {
  final double animationValue;
  final Color waveColor;
  final Color bottleColor;
  _WaveFillPainter({
    required this.animationValue,
    required this.waveColor,
    required this.bottleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = BottleNoteLogoPath().buildCombinedBottleNoteLogoPath();
    canvas.save();
    canvas.clipPath(path);

    const waveHeight = 8.0;
    final double fillPercent = animationValue;
    final double fillHeight = size.height * (1 - fillPercent);
    final waveLength = size.width / 1.5;
    final waveSpeed = animationValue * 2 * pi;
    final Path wavePath = Path();
    wavePath.moveTo(0, fillHeight);
    for (double x = 0; x <= size.width; x++) {
      double y =
          fillHeight + sin((x / waveLength * 2 * pi) + waveSpeed) * waveHeight;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    canvas.drawPath(
        path,
        Paint()
          ..color = bottleColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(
      wavePath,
      Paint()..color = waveColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaveFillPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
