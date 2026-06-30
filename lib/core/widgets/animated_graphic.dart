import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

/// Renders a (possibly SMIL/CSS-animated) SVG asset inside a WebView.
/// The SVG is loaded as-is — its embedded `@keyframes` and `<animate>`
/// elements play natively.
class AnimatedGraphic extends StatefulWidget {
  const AnimatedGraphic({
    super.key,
    required this.assetPath,
    this.padding = EdgeInsets.zero,
  });

  final String assetPath;
  final EdgeInsets padding;

  @override
  State<AnimatedGraphic> createState() => _AnimatedGraphicState();
}

class _AnimatedGraphicState extends State<AnimatedGraphic> {
  late final WebViewController _controller;
  bool _isLoading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent);
    _loadSvg();
  }

  @override
  void didUpdateWidget(covariant AnimatedGraphic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    try {
      final svgString = await rootBundle.loadString(widget.assetPath);
      final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body, html {
      margin: 0; padding: 0; width: 100%; height: 100%;
      overflow: hidden; background-color: transparent;
      display: flex; justify-content: center; align-items: center;
    }
    svg { width: 100%; height: 100%; }
  </style>
</head>
<body>
  $svgString
  <script>
    const svg = document.querySelector('svg');
    if (svg) {
      svg.setAttribute('preserveAspectRatio', 'xMidYMid slice');
      svg.setCurrentTime(0);
    }
  </script>
</body>
</html>
      ''';
      if (mounted) {
        await _controller.loadHtmlString(html);
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loadError != null) {
      return Padding(
        padding: widget.padding,
        child: Container(
          color: cs.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: cs.onSurfaceVariant,
            size: 28,
          ),
        ),
      );
    }
    return Padding(
      padding: widget.padding,
      child: _isLoading
          ? Container(
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
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
