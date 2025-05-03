import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener todos los usuarios registrados en Firestore
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final adminsSnapshot = await _firestore.collection('admins').get();

      final adminUids = adminsSnapshot.docs.map((doc) => doc.id).toSet();

      return usersSnapshot.docs.map((doc) {
        return {
          'uid': doc.id,
          ...doc.data(),
          'isAdmin': adminUids.contains(doc.id),
        };
      }).toList();
    } catch (e) {
      print('Error al obtener usuarios: $e');
      throw Exception('Error cargando usuarios');
    }
  }

  // Verificar si el usuario actual es admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
    return adminDoc.exists;
  }

  // Convertir usuario en admin
  Future<void> promoteToAdmin(String uid, String email) async {
    await _firestore.collection('admins').doc(uid).set({
      'email': email,
      'promotedAt': FieldValue.serverTimestamp(),
      'promotedBy': _auth.currentUser?.uid,
    });
  }

  // Remover permisos de admin
  Future<void> demoteAdmin(String uid) async {
    await _firestore.collection('admins').doc(uid).delete();
  }

  // Obtener datos del usuario actual con información de Auth + Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isAdmin = await isCurrentUserAdmin();

      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'isAdmin': isAdmin,
        ...?userDoc.data(),
      };
    } catch (e) {
      print('Error obteniendo datos usuario: $e');
      return null;
    }
  }
}
