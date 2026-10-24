import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lockify/utils/app_logger.dart';
import 'package:lockify/utils/contacts.dart' as contact_util;

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleSignInInitialization;

  // Cache for local contacts to avoid re-scanning the phone book
  List<Contact>? _cachedContacts;
  DateTime? _lastContactFetch;

  Future<List<Contact>> getCachedContacts(BuildContext context) async {
    final now = DateTime.now();
    if (_cachedContacts != null && _lastContactFetch != null) {
      if (now.difference(_lastContactFetch!).inMinutes < 5) {
        return _cachedContacts!;
      }
    }

    _cachedContacts = await contact_util.getContacts(context);
    _lastContactFetch = now;
    return _cachedContacts!;
  }

  void clearCache() {
    _cachedContacts = null;
    _lastContactFetch = null;
  }

  // Resolve a name from phone using local contacts and optional Firestore fallback
  String resolveName({
    required String phone,
    required List<Contact> localContacts,
    Map<String, dynamic>? dbNames,
  }) {
    if (phone.isEmpty) return "User";
    final normalized = normalizePhone(phone);

    // 1. Priority: Local Contacts
    for (var contact in localContacts) {
      if (contact.phones.isNotEmpty &&
          normalizePhone(contact.phones.first.number) == normalized) {
        final displayName = contact.displayName;
        if (displayName != null && displayName.isNotEmpty) return displayName;
      }
    }

    // 2. Fallback: Firestore Names Map (if provided)
    if (dbNames != null && dbNames.containsKey(normalized)) {
      final name = dbNames[normalized] as String?;
      if (name != null && name.isNotEmpty && name != "User") return name;
    }

    // 3. Last Resort: Raw Phone
    return phone;
  }

  // Helper to normalize phone numbers (extract last 10 digits)
  String normalizePhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }

  // sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String username,
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final normalizedPhone = normalizePhone(phone);

      // save user data to Firestore
      _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'uid': userCredential.user?.uid,
        'username': username,
        'name': name,
        'phone': normalizedPhone,
        'password': password,
        'lastLogin': DateTime.now(),
        'isBanned': false,
        'isVerified': false,
      }, SetOptions(merge: true));
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      } else {
        throw Exception('Failed to sign up: ${e.message}');
      }
    }
  }

  // send email verification
  Future<void> verifyEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }
    await user.reload(); // Refresh user data
    if (user.emailVerified) {
      throw Exception('Email is already verified.');
    }
    await user.sendEmailVerification();
    return Future.value();
  }

  // sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // save user data to Firestore if not already exists
      _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'uid': userCredential.user?.uid,
        'lastLogin': DateTime.now(),
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided.');
      } else {
        throw Exception('Failed to sign in: ${e.message}');
      }
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogleSignIn();
    final googleUser = await _googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Save user data to Firestore if needed
    await _firestore.collection('users').doc(userCredential.user?.uid).set({
      'email': userCredential.user?.email,
      'name': userCredential.user?.displayName,
      'uid': userCredential.user?.uid,
      'lastLogin': DateTime.now(),
    }, SetOptions(merge: true));

    return userCredential;
  }

  Future<void> _initializeGoogleSignIn() {
    return _googleSignInInitialization ??= _googleSignIn.initialize();
  }

  // sign out
  Future<void> signOut() async {
    try {
      // Check if the user logged in with Google
      final user = _auth.currentUser;
      if (user != null && user.providerData.isNotEmpty) {
        for (var provider in user.providerData) {
          if (provider.providerId == 'google.com') {
            // Sign out from Google
            await _initializeGoogleSignIn();
            await _googleSignIn.signOut();
          }
        }
      } else {
        // Sign out from other providers
        await _auth.signOut();
      }
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else {
        throw Exception('Failed to send password reset email: ${e.message}');
      }
    }
  }

  // check if email exists
  Future<bool> emailExists(String email) async {
    final query =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    return query.docs.isNotEmpty;
  }

  // Update user presence (Online/Offline)
  Future<void> updateUserPresence(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        AppLogger.error('Error updating presence', error: e);
      }
    }
  }

  // get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get multiple users by their UIDs
  Future<List<Map<String, dynamic>>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];

    List<Map<String, dynamic>> users = [];
    // Firestore 'whereIn' limit is 30, so we chunk the UIDs
    for (var i = 0; i < uids.length; i += 30) {
      final chunk = uids.sublist(
        i,
        i + 30 > uids.length ? uids.length : i + 30,
      );
      final query =
          await _firestore
              .collection('users')
              .where('uid', whereIn: chunk)
              .get();
      users.addAll(query.docs.map((doc) => doc.data()));
    }
    return users;
  }

  // Get current user phone number from Firestore
  Future<String> getCurrentUserPhone() async {
    final user = _auth.currentUser;
    if (user == null) return "";

    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      return normalizePhone(user.phoneNumber!);
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final phone = doc.data()?['phone'] ?? "";
    return normalizePhone(phone);
  }

  // Get current user name with fallbacks
  Future<String> getCurrentUserName() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data();

    final name = data?['name'] as String?;
    if (name != null && name.isNotEmpty) return name;

    final firstName = data?['firstName'] as String? ?? "";
    final lastName = data?['lastName'] as String? ?? "";
    final fullName = "$firstName $lastName".trim();
    if (fullName.isNotEmpty) return fullName;

    final phone = data?['phone'] as String?;
    if (phone != null && phone.isNotEmpty) return phone;

    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@')[0];
    }

    return "User";
  }
}
