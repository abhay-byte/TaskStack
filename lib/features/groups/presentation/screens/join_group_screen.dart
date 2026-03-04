import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:taskstack/features/groups/presentation/providers/group_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final MobileScannerController _scanCtrl = MobileScannerController();
  final _codeCtrl = TextEditingController();
  bool _scanned = false;
  bool _scanning = true;

  @override
  void dispose() {
    _scanCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join(String code) async {
    if (_scanned) return;
    _scanned = true;
    _scanCtrl.stop();

    setState(() => _scanning = false);

    final ok = await ref
        .read(groupNotifierProvider.notifier)
        .joinByCode(code);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined group successfully!')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or already joined.')),
      );
      setState(() {
        _scanned = false;
        _scanning = true;
      });
      _scanCtrl.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Join a Group'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
              Tab(icon: Icon(Icons.keyboard), text: 'Enter Code'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── QR Scanner tab ───────────────────────────────────────────
            _scanning
                ? Stack(
                    children: [
                      MobileScanner(
                        controller: _scanCtrl,
                        onDetect: (capture) {
                          final barcode = capture.barcodes.firstOrNull;
                          final raw = barcode?.rawValue;
                          if (raw == null) return;
                          // Parse taskstack://join?code=XXX
                          String code = raw;
                          try {
                            final uri = Uri.parse(raw);
                            code = uri.queryParameters['code'] ?? raw;
                          } catch (_) {}
                          _join(code);
                        },
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Card(
                            color: cs.surface.withAlpha(200),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Point at a TaskStack group QR code',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),

            // ── Manual code tab ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Invite Code',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) _join(v.trim());
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final code = _codeCtrl.text.trim();
                      if (code.isNotEmpty) _join(code);
                    },
                    child: const Text('Join Group'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
