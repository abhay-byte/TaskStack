import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when the user is running in guest/offline mode (no account).
/// Toggled by [AuthNotifier.continueAsGuest()] and reset on login/register.
final isGuestModeProvider = StateProvider<bool>((ref) => false);
