import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String? _officeId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _collectors = [];

  @override
  void initState() {
    super.initState();
    _loadOfficeData();
    _loadCollectors();
  }

  Future<void> _loadOfficeData() async {
    final userData = await _userService.getCurrentUserData();
    setState(() {
      _officeId = userData?['officeId'];
    });
  }

  Future<void> _loadCollectors() async {
    if (_officeId == null) return;

    setState(() => _isLoading = true);
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('officeId', isEqualTo: _officeId)
              .where('role', isEqualTo: 'collector')
              .get();

      setState(() {
        _collectors =
            querySnapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerCollector() async {
    if (!_formKey.currentState!.validate() || _officeId == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. Crear usuario en Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Guardar datos extendidos en Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'role': 'collector',
        'officeId': _officeId,
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // 3. Actualizar lista
      await _loadCollectors();

      // 4. Mostrar feedback y limpiar formulario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cobrador registrado exitosamente')),
        );
        _formKey.currentState?.reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCollectorStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _loadCollectors();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando estado: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Oficina')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar Nuevo Cobrador',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el nombre del cobrador';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Ingrese un email válido';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _registerCollector,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Registrar Cobrador'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Cobradores Registrados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _collectors.isEmpty
                      ? const Center(
                        child: Text('No hay cobradores registrados'),
                      )
                      : ListView.builder(
                        itemCount: _collectors.length,
                        itemBuilder: (context, index) {
                          final collector = _collectors[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(collector['name'] ?? 'Sin nombre'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(collector['email'] ?? 'Sin email'),
                                  Text(
                                    'Registrado: ${_formatDate(collector['createdAt'])}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Switch(
                                value: collector['isActive'] ?? false,
                                onChanged:
                                    (value) => _toggleCollectorStatus(
                                      collector['id'],
                                      value,
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Fecha desconocida';
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(date.toDate());
    }
    return date.toString();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
