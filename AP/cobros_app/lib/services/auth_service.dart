import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // Registro básico con email y contraseña
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
    String? officeId,
    String? displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _createUserProfile(
        user: userCredential.user!,
        role: role,
        officeId: officeId,
        displayName: displayName,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // Registro completo con rol y oficina
  Future<User?> registerUserWithRole({
    required String email,
    required String password,
    required String role,
    String? officeId,
    String? officeName,
    String? displayName,
  }) async {
    try {
      // Crear oficina si es dueño y se provee nombre
      String? newOfficeId;
      if (role == 'owner' && officeName != null) {
        final officeRef = await _firestore.collection('offices').add({
          'name': officeName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        newOfficeId = officeRef.id;
      }

      // Registrar usuario
      final user = await registerWithEmailAndPassword(
        email: email,
        password: password,
        role: role,
        officeId: newOfficeId ?? officeId,
        displayName: displayName,
      );

      return user;
    } catch (e) {
      if (currentUser != null) await currentUser!.delete();
      rethrow;
    }
  }

  // Inicio de sesión con email y contraseña
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

  // Inicio de sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Crear perfil si es nuevo usuario
      if (userCredential.additionalUserInfo!.isNewUser) {
        await _createUserProfile(
          user: userCredential.user!,
          role: 'user', // Rol por defecto
          displayName: googleUser.displayName,
        );
      }

      return userCredential.user;
    } catch (e) {
      print('Error en Google Sign-In: $e');
      return null;
    }
  }

  // Método para registro básico (usado en RegisterScreen)
  Future<User?> registerUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      return await registerWithEmailAndPassword(
        email: email,
        password: password,
        role: 'user', // Rol por defecto
        displayName: displayName,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Método específico para registrar cobradores (usado en RegisterCollectorScreen)
  Future<User?> registerCollector({
    required String email,
    required String password,
    required String officeId,
    String? displayName,
  }) async {
    try {
      final user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(user.user!.uid).set({
        'email': email,
        'role': 'collector', // <-- Campo crítico
        'officeId': officeId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return user.user;
    } catch (e) {
      print('Error registrando cobrador: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      throw Exception('Error al cerrar sesión');
    }
  }

  // Crear perfil de usuario en Firestore
  Future<void> _createUserProfile({
    required User user,
    required String role,
    String? officeId,
    String? displayName,
  }) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName ?? user.displayName,
      'photoURL': user.photoURL,
      'role': role,
      'officeId': officeId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  // Obtener datos del usuario actual
  Future<Map<String, dynamic>> getCurrentUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) throw Exception('Perfil de usuario no encontrado');

    return {
      'uid': user.uid,
      'email': user.email,
      ...userDoc.data() as Map<String, dynamic>,
    };
  }

  // Manejo de errores de autenticación
  Exception _handleAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return Exception('Credenciales inválidas');
      case 'user-disabled':
        return Exception('Cuenta deshabilitada');
      case 'too-many-requests':
        return Exception('Demasiados intentos. Intente más tarde');
      case 'email-already-in-use':
        return Exception('El correo ya está registrado');
      case 'invalid-email':
        return Exception('Correo electrónico inválido');
      case 'weak-password':
        return Exception('La contraseña debe tener al menos 6 caracteres');
      case 'operation-not-allowed':
        return Exception('Operación no permitida');
      default:
        return Exception('Error de autenticación: $code');
    }
  }
}
