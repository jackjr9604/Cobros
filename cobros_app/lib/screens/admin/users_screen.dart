// screens/admin/users_screen.dart
import 'package:flutter/material.dart';
import '../../../services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() => _users = users);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(user['email'] ?? 'Sin email'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UID: ${user['uid']}'),
                          if (user['createdAt'] != null)
                            Text(
                              'Registrado: ${_formatDate(user['createdAt'])}',
                            ),
                          Text(
                            user['isAdmin']
                                ? 'ROL: ADMINISTRADOR'
                                : 'ROL: USUARIO',
                            style: TextStyle(
                              color:
                                  user['isAdmin'] ? Colors.green : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: user['isAdmin'],
                        onChanged: (value) => _toggleAdminStatus(user, value),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toDate());
    }
    return date.toString();
  }

  Future<void> _toggleAdminStatus(
    Map<String, dynamic> user,
    bool makeAdmin,
  ) async {
    try {
      if (makeAdmin) {
        await _userService.promoteToAdmin(user['uid'], user['email']);
      } else {
        await _userService.demoteAdmin(user['uid']);
      }
      _loadUsers(); // Refrescar lista
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}
