import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== INSCRIPTION ====================
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // ==================== CONNEXION ====================
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // ==================== DÉCONNEXION ====================
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }

  // ==================== RÉINITIALISATION DU MOT DE PASSE ====================
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // ==================== VÉRIFIER SI L'EMAIL EST VÉRIFIÉ ====================
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ==================== ENVOYER UN EMAIL DE VÉRIFICATION ====================
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email de vérification');
    }
  }

  // ==================== SUPPRIMER LE COMPTE ====================
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // ==================== METTRE À JOUR L'EMAIL ====================
  Future<void> updateEmail({required String newEmail}) async {
    try {
      await _auth.currentUser?.updateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // ==================== METTRE À JOUR LE MOT DE PASSE ====================
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // ==================== RÉAUTHENTIFIER L'UTILISATEUR ====================
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
}
