import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an SVG asset using flutter_svg — no WebView overhead.
/// Eliminates per-task WebViewController allocation and native rendering
/// cost that was the primary 120 fps blocker.
class AnimatedGraphic extends StatelessWidget {
  const AnimatedGraphic({
    super.key,
    required this.assetPath,
    this.padding = EdgeInsets.zero,
  });

  final String assetPath;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => Container(
          color: cs.surfaceContainerHighest,
          alignment: Alignment.center,
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
        ),
        errorBuilder: (_, __, ___) => Container(
          color: cs.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: cs.onSurfaceVariant,
            size: 28,
          ),
        ),
      ),
    );
  }
}
