import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Método de registro básico (público)
  Future<User?> registerUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // 1. Registrar usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Crear perfil del usuario en Firestore
      await _createUserProfile(
        user: userCredential.user!,
        displayName: displayName,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // Método para registrar usuarios con roles (admin, owner, collector)
  Future<User?> registerUserWithRole({
    required String email,
    required String password,
    required String role,
    String? officeId, // Para cobradores y dueños
    String? officeName, // Solo para crear nueva oficina con dueño
    String? displayName,
  }) async {
    User? user; // Declaración movida aquí para que sea visible en el catch

    try {
      // Registrar el usuario
      user = await registerUser(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (user == null) return null;

      // Si es dueño y se proporciona nombre de oficina, crear oficina
      String? newOfficeId;
      if (role == 'owner' && officeName != null) {
        final officeRef = await _firestore.collection('offices').add({
          'name': officeName,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser?.uid,
        });
        newOfficeId = officeRef.id;
      }

      // Actualizar perfil con información de rol
      await _firestore.collection('users').doc(user.uid).update({
        'role': role,
        if (newOfficeId != null) 'officeId': newOfficeId,
        if (officeId != null) 'officeId': officeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      // Si falla, eliminar el usuario creado
      if (user != null) {
        await user.delete();
      }
      rethrow;
    }
  }

  // Método para que dueños registren cobradores
  Future<User?> registerCollector({
    required String email,
    required String password,
    required String officeId,
    String? displayName,
  }) async {
    // Verificar que el usuario actual es dueño de esta oficina
    final currentUserData = await getCurrentUserData();
    if (currentUserData?['role'] != 'owner' ||
        currentUserData?['officeId'] != officeId) {
      throw Exception(
        'No tienes permisos para registrar cobradores en esta oficina',
      );
    }

    // Registrar el cobrador
    return registerUserWithRole(
      email: email,
      password: password,
      role: 'collector',
      officeId: officeId,
      displayName: displayName,
    );
  }

  // Método privado para crear perfil inicial
  Future<void> _createUserProfile({
    required User user,
    String? displayName,
  }) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': displayName ?? user.displayName,
      'photoUrl': user.photoURL,
      'role': 'user', // Rol por defecto
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  // Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // Método para iniciar sesión con email y contraseña (antes llamado "login")
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // Método para iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Crear perfil si es nuevo usuario
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      }

      return userCredential.user;
    } catch (e) {
      print('Error en Google Sign-In: $e');
      return null;
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      throw Exception('No se pudo cerrar la sesión correctamente');
    }
  }

  // Manejo de errores
  Exception _handleAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return Exception('Correo o contraseña incorrectos');
      case 'user-disabled':
        return Exception('La cuenta ha sido deshabilitada');
      case 'too-many-requests':
        return Exception('Demasiados intentos. Intenta más tarde');
      case 'invalid-email':
        return Exception('El correo electrónico no es válido');
      default:
        return Exception('Error al iniciar sesión: $code');
    }
  }
}
