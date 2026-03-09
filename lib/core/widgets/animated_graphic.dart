import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

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
    svg { 
      width: 100%; height: 100%; 
    }
  </style>
</head>
<body>
  $svgString
  <script>
    const svg = document.querySelector('svg');
    if (svg) {
      // Use slice to fill the entire header area without white gaps
      svg.setAttribute('preserveAspectRatio', 'xMidYMid slice');
      
      // Force a tiny "kick" to ensure SMIL animations start playing in some WebView versions
      svg.setCurrentTime(0);
    }
  </script>
</body>
</html>
      ''';
      if (mounted) {
        await _controller.loadHtmlString(html);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading SVG for AnimatedGraphic: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: widget.padding,
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: widget.padding,
      child: WebViewWidget(controller: _controller),
    );
  }
}
