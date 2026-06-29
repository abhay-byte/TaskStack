import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/settings/presentation/providers/settings_provider.dart';

/// Local-only profile screen. Display name is stored in SharedPreferences.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final prefs = ref.read(sharedPreferencesProvider);
    _displayNameCtrl.text = prefs.getString('profile_display_name') ?? '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(
        'profile_display_name',
        _displayNameCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayName = _displayNameCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: cs.primaryContainer,
                child: displayName.isNotEmpty
                    ? Text(
                        displayName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 36,
                          color: cs.onPrimaryContainer,
                        ),
                      )
                    : Icon(Icons.person, color: cs.onPrimaryContainer, size: 36),
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _displayNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              maxLength: 60,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
