import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'users_screen.dart';
import 'offices_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final UserService _userService = UserService();
  int _userCount = 0;
  int _officeCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final users = await _userService.getAllUsers();
    final offices =
        await FirebaseFirestore.instance.collection('offices').get();

    setState(() {
      _userCount = users.length;
      _officeCount = offices.size;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panel de Administración',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildStatCard(
                          'Usuarios',
                          _userCount,
                          Icons.people,
                          Colors.blue,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UsersScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Oficinas',
                          _officeCount,
                          Icons.business,
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OfficesScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Acciones Rápidas:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text('Nuevo Admin'),
                          onPressed: () => _showAddUserDialog('admin'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.add_business, size: 18),
                          label: const Text('Nueva Oficina'),
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OfficesScreen(),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog(String role) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Registrar nuevo ${role == 'admin' ? 'Administrador' : 'Dueño'}',
            ),
            content: AddUserForm(role: role),
          ),
    );
  }
}

class AddUserForm extends StatefulWidget {
  final String role;

  const AddUserForm({super.key, required this.role});

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator:
                (value) => value!.contains('@') ? null : 'Email inválido',
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
            validator:
                (value) => value!.length >= 6 ? null : 'Mínimo 6 caracteres',
          ),
          if (widget.role == 'owner')
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Oficina',
              ),
              validator: (value) => value!.isEmpty ? 'Requerido' : null,
            ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                onPressed: _registerUser,
                child: const Text('Registrar'),
              ),
        ],
      ),
    );
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      final user = await authService.registerWithRole(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: widget.role,
        officeName: widget.role == 'owner' ? _nameController.text.trim() : null,
      );

      if (user != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado exitosamente')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
