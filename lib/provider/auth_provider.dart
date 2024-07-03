import 'package:firebase_auth/firebase_auth.dart';

import '../auth/auth_error.dart';

abstract class AuthProvider {
  String? get userId;
  Future<bool> deleteAccountAndSignOut();
  Future<void> signOut();
  Future<bool> register({
    required String email,
    required String password,
  });
  Future<bool> login({
    required String email,
    required String password,
  });
}

class FirebaseAuthProvider extends AuthProvider {
  @override
  Future<bool> deleteAccountAndSignOut() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      return false;
    }
    try {
      // Delete the user from firebase
      await user.delete();
      // logout the user
      await auth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      final authError = AuthError.from(e);
      throw authError;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      final authError = AuthError.from(e);
      throw authError;
    }
    return FirebaseAuth.instance.currentUser != null;
  }

  @override
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      final authError = AuthError.from(e);
      throw authError;
    }
    return FirebaseAuth.instance.currentUser != null;
  }

  @override
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      rethrow;
    }
  }

  @override
  String? get userId => FirebaseAuth.instance.currentUser?.uid;
}
