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
      throw Exception('Username must be 3-30 chars, letters/numbers/underscore only.');
    }

    // Atomically reserve username via Firestore transaction
    final usernameDoc = _firestore.collection('usernames').doc(username);
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
    final resolvedDisplay = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : username;

    try {
      // Use a batch: reserve username + create user profile atomically
      final batch = _firestore.batch();
      final userDoc = _firestore.collection('users').doc(uid);

      batch.set(usernameDoc, {'uid': uid});
      batch.set(userDoc, {
        'uid': uid,
        'username': username,
        'email': email,
        'displayName': resolvedDisplay,
        'bio': null,
        'avatarUrl': null,
        'isPublic': false,
        'createdAt': now,
      });
      await batch.commit();
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

    final userCred = await _auth.signInWithCredential(credential);
    final uid = userCred.user!.uid;
    final isNewUser = userCred.additionalUserInfo?.isNewUser ?? false;

    if (isNewUser) {
      // First time — create Firestore profile
      final resolvedUsername = username != null && username.isNotEmpty
          ? username
          : _sanitizeUsername(googleUser.displayName ?? googleUser.email) +
              uid.substring(0, 4);

      final resolvedDisplay = googleUser.displayName?.isNotEmpty == true
          ? googleUser.displayName!
          : resolvedUsername;

      // Reserve username + create profile atomically
      final usernameDoc =
          _firestore.collection('usernames').doc(resolvedUsername);
      final userDoc = _firestore.collection('users').doc(uid);
      final batch = _firestore.batch();
      batch.set(usernameDoc, {'uid': uid});
      batch.set(userDoc, {
        'uid': uid,
        'username': resolvedUsername,
        'email': googleUser.email,
        'displayName': resolvedDisplay,
        'avatarUrl': googleUser.photoUrl,
        'bio': null,
        'isPublic': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      return AuthUser(
        id: uid,
        username: resolvedUsername,
        email: googleUser.email,
        displayName: resolvedDisplay,
        avatarUrl: googleUser.photoUrl,
      );
    } else {
      // Returning user — just read profile
      return await _fetchProfile(uid);
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
    await _deleteCollection(_firestore.collection('users').doc(uid).collection('tasks'));
    await _deleteCollection(_firestore.collection('users').doc(uid).collection('goals'));

    // Remove from all groups
    final memberSnaps = await _firestore
        .collection('group_members')
        .where('userId', isEqualTo: uid)
        .get();
    final batch = _firestore.batch();
    for (final doc in memberSnaps.docs) {
      batch.delete(doc.reference);
    }

    // Remove invites
    final inviteSnaps = await _firestore
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
      return await _fetchProfile(user.uid);
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
        return await _fetchProfile(user.uid);
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

  String _sanitizeUsername(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .substring(0, raw.length.clamp(0, 20));
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
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
  return AuthRepositoryImpl(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});
