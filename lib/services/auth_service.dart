import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String riskProfile;
  final int healthScore;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.riskProfile = 'Moderate',
    this.healthScore = 78,
  });

  UserModel copyWith({
    String? displayName,
    String? riskProfile,
    int? healthScore,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      riskProfile: riskProfile ?? this.riskProfile,
      healthScore: healthScore ?? this.healthScore,
    );
  }
}

class AuthService extends ChangeNotifier {
  late final FirebaseAuth _auth;
  
  UserModel? _currentUser;
  bool _isFirebaseEnabled = false;

  UserModel? get currentUser => _currentUser;
  bool get isFirebaseEnabled => _isFirebaseEnabled;

  AuthService() {
    _checkFirebase();
  }

  void _checkFirebase() {
    try {
      _auth = FirebaseAuth.instance;
      // Check if Firebase is initialized and usable
      if (_auth.app != null) {
        _isFirebaseEnabled = true;
        _auth.authStateChanges().listen((User? user) {
          if (user != null) {
            _currentUser = UserModel(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? 'FinMate User',
            );
          } else {
            _currentUser = null;
          }
          notifyListeners();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Firebase Auth not initialized, using Mock AuthService: $e");
      }
      _isFirebaseEnabled = false;
      // Pre-login a mock user for instant review
      _currentUser = UserModel(
        uid: 'mock_user_123',
        email: 'demo@finmate.ai',
        displayName: 'Nikhil Sharma',
        riskProfile: 'Moderate',
        healthScore: 82,
      );
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    if (_isFirebaseEnabled) {
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        return true;
      } catch (e) {
        if (kDebugMode) print("Login Error: $e");
        return false;
      }
    } else {
      // Mock Login
      _currentUser = UserModel(
        uid: 'mock_user_123',
        email: email,
        displayName: email.split('@')[0].toUpperCase(),
      );
      notifyListeners();
      return true;
    }
  }

  Future<bool> registerWithEmail(String email, String password, String name) async {
    if (_isFirebaseEnabled) {
      try {
        UserCredential creds = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        await creds.user?.updateDisplayName(name);
        _currentUser = UserModel(
          uid: creds.user!.uid,
          email: email,
          displayName: name,
        );
        notifyListeners();
        return true;
      } catch (e) {
        if (kDebugMode) print("Register Error: $e");
        return false;
      }
    } else {
      // Mock Register
      _currentUser = UserModel(
        uid: 'mock_user_123',
        email: email,
        displayName: name,
      );
      notifyListeners();
      return true;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '499015652052-r75bncdjfp20soamc3s6ad2hg1iqb0qc.apps.googleusercontent.com' : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;

      // Update local state with the actual selected Google account
      _currentUser = UserModel(
        uid: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName ?? 'Google User',
      );

      if (_isFirebaseEnabled) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
      
      notifyListeners();
      return true; 
    } catch (e) {
      if (kDebugMode) print("Google Sign-In Error: $e");
      return false;
    }
  }

  Future<void> sendForgotPasswordEmail(String email) async {
    if (_isFirebaseEnabled) {
      await _auth.sendPasswordResetEmail(email: email);
    } else {
      if (kDebugMode) print("Mock password reset email sent to $email");
    }
  }

  Future<void> updateProfile({String? displayName, String? riskProfile, int? healthScore}) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        riskProfile: riskProfile,
        healthScore: healthScore,
      );
      if (_isFirebaseEnabled) {
        if (displayName != null) {
          await _auth.currentUser?.updateDisplayName(displayName);
        }
      }
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_isFirebaseEnabled) {
      await _auth.signOut();
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }
}
