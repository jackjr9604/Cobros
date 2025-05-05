import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin/users_screen.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener todos los usuarios registrados en Firestore
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final usersSnapshot = await _firestore.collection('users').get();

    return usersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        ...data,
        'isAdmin': data['role'] == 'admin',
        'isOwner': data['role'] == 'owner',
        'isCollector': data['role'] == 'collector',
      };
    }).toList();
  }

  // Verificar si el usuario actual es admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.exists && userDoc.data()?['role'] == 'admin';
  }

  // Convertir usuario en admin
  Future<void> promoteToAdmin(String uid, String admin) async {
    await _firestore.collection('users').doc(uid).set({
      'role': admin,
      'promotedAt': FieldValue.serverTimestamp(),
      'promotedBy': _auth.currentUser?.uid,
    });
  }

  // Remover permisos de admin
  Future<void> demoteAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // Obtener datos del usuario actual con información de Auth + Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        print('Documento de usuario no existe');
        return null;
      }

      return {
        'uid': user.uid,
        'email': user.email,
        'role': doc.data()?['role'] ?? 'user', // Asegurar campo role
        'officeId': doc.data()?['officeId'],
      };
    } catch (e) {
      print('Error detallado: $e'); // Log más descriptivo
      return null;
    }
  }
}
