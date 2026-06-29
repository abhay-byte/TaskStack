import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:taskstack/features/settings/presentation/providers/settings_provider.dart';

/// Local-only profile screen. Display name and profile picture are stored locally.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _saving = false;
  String? _photoPath;

  static const _kDisplayName = 'profile_display_name';
  static const _kPhotoPath = 'profile_photo_path';

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
    _displayNameCtrl.text = prefs.getString(_kDisplayName) ?? '';
    _photoPath = prefs.getString(_kPhotoPath);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(
        _kDisplayName,
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

  Future<void> _pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_photo${path.extension(picked.path)}';
      final saved = await File(picked.path).copy('${appDir.path}/$fileName');

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_kPhotoPath, saved.path);
      setState(() => _photoPath = saved.path);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Photo update failed: $e')));
      }
    }
  }

  Future<void> _removePhoto() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedPath = prefs.getString(_kPhotoPath);
    if (savedPath != null) {
      try {
        final file = File(savedPath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Ignore cleanup errors.
      }
    }
    await prefs.remove(_kPhotoPath);
    setState(() => _photoPath = null);
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto();
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayName = _displayNameCtrl.text.trim();
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage:
                        hasPhoto ? FileImage(File(_photoPath!)) : null,
                    child: !hasPhoto
                        ? (displayName.isNotEmpty
                            ? Text(
                                displayName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 44,
                                  color: cs.onPrimaryContainer,
                                ),
                              )
                            : Icon(Icons.person,
                                color: cs.onPrimaryContainer, size: 44))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _showPhotoOptions,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.primary,
                        child: Icon(
                          hasPhoto ? Icons.edit : Icons.camera_alt,
                          size: 18,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
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
              onChanged: (_) => setState(() {}),
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
