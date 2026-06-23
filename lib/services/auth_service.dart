import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;
  bool _listenerInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<UserModel?> _loadUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    final authUser = _auth.currentUser;
    if (authUser == null) return null;
    final fallback = UserModel(
      uid: uid,
      email: authUser.email ?? '',
      displayName: authUser.displayName ?? 'User',
      role: 'kreator',
      totalPlasticDiverted: 0,
      totalCo2Offset: 0,
      createdAt: Timestamp.now(),
    );
    await _firestore.collection('users').doc(uid).set(fallback.toMap());
    return fallback;
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final user = credential.user;
      if (user == null) {
        _setError('Gagal masuk ke akun.');
        return false;
      }
      _currentUser = await _loadUserFromFirestore(user.uid);
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (error) {
      _setError(_friendlyAuthMessage(error));
      return false;
    } catch (_) {
      _setError('Terjadi kesalahan saat masuk.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password, String displayName, String role) async {
    try {
      _setLoading(true);
      _setError(null);
      final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final user = credential.user;
      if (user == null) {
        _setError('Gagal membuat akun.');
        return false;
      }
      await user.updateDisplayName(displayName);
      final normalizedRole = role.isEmpty ? 'kreator' : role;
      final newUser = UserModel(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        role: normalizedRole,
        totalPlasticDiverted: 0,
        totalCo2Offset: 0,
        createdAt: Timestamp.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      _currentUser = newUser;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      _setError(_friendlyAuthMessage(error));
      return false;
    } catch (_) {
      _setError('Terjadi kesalahan saat mendaftar.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void initAuthListener() {
    if (_listenerInitialized) return;
    _listenerInitialized = true;
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentUser = null;
        notifyListeners();
        return;
      }
      _currentUser = await _loadUserFromFirestore(user.uid);
      notifyListeners();
    });
  }

  Future<void> updateUserImpactStats(double plasticGrams, double co2Grams) async {
    final uid = _currentUser?.uid ?? _auth.currentUser?.uid;
    if (uid == null) return;
    final userRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final updatedPlastic = (data['totalPlasticDiverted'] as num?)?.toDouble() ?? 0;
      final updatedCo2 = (data['totalCo2Offset'] as num?)?.toDouble() ?? 0;
      transaction.update(userRef, {
        'totalPlasticDiverted': updatedPlastic + plasticGrams,
        'totalCo2Offset': updatedCo2 + co2Grams,
      });
    });

    final current = _currentUser;
    if (current != null) {
      _currentUser = current.copyWith(
        totalPlasticDiverted: current.totalPlasticDiverted + plasticGrams,
        totalCo2Offset: current.totalCo2Offset + co2Grams,
      );
      notifyListeners();
    }
  }

  String _friendlyAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      default:
        return 'Autentikasi gagal. Coba lagi.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
