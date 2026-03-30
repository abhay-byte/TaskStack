import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:taskstack/firebase_options.dart';
import 'package:taskstack/features/auth/domain/entities/auth_user.dart';
import 'package:taskstack/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: DefaultFirebaseOptions.webClientId,
  );

  // ── Register ───────────────────────────────────────────────────────────────

  @override
  Future<AuthUser> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    // Validate username format
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
    if (!usernameRegex.hasMatch(username)) {
      throw Exception(
        'Username must be 3-30 chars, letters/numbers/underscore only.',
      );
    }

    final UserCredential cred;

    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_authError(e));
    }

    final uid = cred.user!.uid;
    final now = FieldValue.serverTimestamp();
    final resolvedDisplay =
        (displayName != null && displayName.isNotEmpty)
            ? displayName
            : username;

    try {
      final created = await _createProfileWithUsername(
        uid: uid,
        username: username,
        email: email,
        displayName: resolvedDisplay,
        avatarUrl: null,
        createdAt: now,
      );
      if (!created) {
        throw Exception('Username already taken.');
      }
    } catch (e) {
      // Roll back Firebase Auth user if Firestore write fails
      await cred.user!.delete();
      rethrow;
    }

    return AuthUser(
      id: uid,
      username: username,
      email: email,
      displayName: resolvedDisplay,
    );
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  @override
  Future<AuthUser> signInWithGoogle({String? username}) async {
    // Trigger the Google Sign-In flow
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled.');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      final userCred = await _auth.signInWithCredential(credential);
      final firebaseUser = userCred.user;
      if (firebaseUser == null) {
        throw Exception('Google sign-in failed.');
      }

      final uid = firebaseUser.uid;
      final profileRef = _firestore.collection('users').doc(uid);
      final profileSnap = await profileRef.get();
      if (profileSnap.exists) {
        return _fetchProfile(uid);
      }

      final resolvedDisplay =
          googleUser.displayName?.trim().isNotEmpty == true
              ? googleUser.displayName!.trim()
              : _normalizeUsername(username) ??
                  _normalizeUsername(googleUser.displayName) ??
                  _normalizeUsername(googleUser.email.split('@').first) ??
                  'taskstack';

      await _createGoogleProfile(
        uid: uid,
        preferredUsername: username,
        googleDisplayName: googleUser.displayName,
        email: googleUser.email,
        displayName: resolvedDisplay,
        avatarUrl: googleUser.photoUrl,
      );

      return _fetchProfile(uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authError(e));
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _fetchProfile(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authError(e));
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut(); // clear Google credential state
    await _auth.signOut();
  }

  // ── Delete Account ─────────────────────────────────────────────────────────

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in.');
    final uid = user.uid;

    // Fetch username before deleting profile
    final userSnap = await _firestore.collection('users').doc(uid).get();
    final username = userSnap.data()?['username'] as String?;

    // Delete all sub-collections and top-level docs
    await _deleteCollection(
      _firestore.collection('users').doc(uid).collection('tasks'),
    );
    await _deleteCollection(
      _firestore.collection('users').doc(uid).collection('goals'),
    );

    // Remove from all groups
    final memberSnaps =
        await _firestore
            .collection('group_members')
            .where('userId', isEqualTo: uid)
            .get();
    final batch = _firestore.batch();
    for (final doc in memberSnaps.docs) {
      batch.delete(doc.reference);
    }

    // Remove invites
    final inviteSnaps =
        await _firestore
            .collection('invites')
            .where('invitedUserId', isEqualTo: uid)
            .get();
    for (final doc in inviteSnaps.docs) {
      batch.delete(doc.reference);
    }

    // Delete user profile + username reservation
    batch.delete(_firestore.collection('users').doc(uid));
    if (username != null) {
      batch.delete(_firestore.collection('usernames').doc(username));
    }
    await batch.commit();

    // Delete Firebase Auth account last
    await user.delete();
  }

  // ── Current User ───────────────────────────────────────────────────────────

  @override
  Future<AuthUser?> currentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchOrBootstrapProfile(user);
    } catch (_) {
      return null;
    }
  }

  // ── Auth State Stream ──────────────────────────────────────────────────────

  @override
  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        return await _fetchOrBootstrapProfile(user);
      } catch (_) {
        return null;
      }
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<AuthUser> _fetchProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) throw Exception('User profile not found.');
    return AuthUser(
      id: uid,
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }

  Future<AuthUser?> _fetchOrBootstrapProfile(User user) async {
    try {
      return await _fetchProfile(user.uid);
    } catch (_) {
      final email = user.email;
      final isGoogleUser = user.providerData.any(
        (provider) => provider.providerId == 'google.com',
      );
      if (!isGoogleUser || email == null) {
        return null;
      }

      final resolvedDisplay =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : _normalizeUsername(email.split('@').first) ?? 'taskstack';

      await _createGoogleProfile(
        uid: user.uid,
        preferredUsername: null,
        googleDisplayName: user.displayName,
        email: email,
        displayName: resolvedDisplay,
        avatarUrl: user.photoURL,
      );
      return _fetchProfile(user.uid);
    }
  }

  Future<void> _deleteCollection(CollectionReference col) async {
    QuerySnapshot snap;
    do {
      snap = await col.limit(100).get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      if (snap.docs.isNotEmpty) await batch.commit();
    } while (snap.docs.length == 100);
  }

  Future<bool> _createProfileWithUsername({
    required String uid,
    required String username,
    required String email,
    required String displayName,
    required Object? createdAt,
    String? avatarUrl,
  }) {
    final usernameRef = _firestore.collection('usernames').doc(username);
    final userRef = _firestore.collection('users').doc(uid);

    return _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (userSnap.exists) return true;

      final usernameSnap = await tx.get(usernameRef);
      if (usernameSnap.exists) return false;

      tx.set(usernameRef, {'uid': uid});
      tx.set(userRef, {
        'uid': uid,
        'username': username,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'bio': null,
        'isPublic': false,
        'createdAt': createdAt,
      });
      return true;
    });
  }

  Future<void> _createGoogleProfile({
    required String uid,
    String? preferredUsername,
    String? googleDisplayName,
    required String email,
    required String displayName,
    String? avatarUrl,
  }) async {
    final baseCandidates = <String>[
      if (_normalizeUsername(preferredUsername) case final preferred
          when preferred != null)
        preferred,
      if (_normalizeUsername(googleDisplayName) case final display
          when display != null)
        display,
      if (_normalizeUsername(email.split('@').first) case final local
          when local != null)
        local,
    ];

    final uniqueBases = <String>{...baseCandidates, 'taskstack'};
    for (final base in uniqueBases) {
      for (var index = 0; index < 12; index++) {
        final suffix = index == 0 ? '' : '_${uid.substring(0, 4)}$index';
        final candidate = _trimUsername('$base$suffix');
        if (candidate.length < 3) continue;

        final created = await _createProfileWithUsername(
          uid: uid,
          username: candidate,
          email: email,
          displayName: displayName,
          avatarUrl: avatarUrl,
          createdAt: FieldValue.serverTimestamp(),
        );
        if (created) {
          return;
        }
      }
    }

    throw Exception(
      'Could not create a username for this Google account. Please try again.',
    );
  }

  String? _normalizeUsername(String? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.isEmpty) return null;
    return _trimUsername(cleaned);
  }

  String _trimUsername(String value) {
    if (value.length <= 20) return value;
    return value.substring(0, 20);
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'That email already exists with another sign-in method.';
      case 'email-already-in-use':
        return 'Email already taken.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak (min 8 chars).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid credentials.';
      case 'user-disabled':
        return 'Account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(FirebaseAuth.instance, FirebaseFirestore.instance);
});
