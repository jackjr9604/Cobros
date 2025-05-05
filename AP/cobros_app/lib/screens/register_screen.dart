import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importación añadida
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final String?
  role; // 'admin', 'owner', 'collector' o null para usuario normal
  final String? officeId; // Requerido para collector

  const RegisterScreen({super.key, this.role, this.officeId});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _officeNameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (widget.role == 'owner')
                  TextFormField(
                    controller: _officeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Oficina',
                      hintText: 'Ej: Oficina Central',
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Este campo es requerido' : null,
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Este campo es requerido' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (value) =>
                          value!.contains('@')
                              ? null
                              : 'Ingrese un email válido',
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator:
                      (value) =>
                          value!.length >= 6
                              ? null
                              : 'La contraseña debe tener al menos 6 caracteres',
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _register,
                      child: Text(
                        widget.role != null
                            ? 'Registrar ${_getRoleName(widget.role!)}'
                            : 'Registrarse',
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'owner':
        return 'Dueño de Oficina';
      case 'collector':
        return 'Cobrador';
      default:
        return 'Usuario';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final displayName = _nameController.text.trim();

      User? user;
      if (widget.role == null) {
        // Registro de usuario normal
        user = await _authService.registerUser(
          email: email,
          password: password,
          displayName: displayName,
        );
      } else {
        // Registro con rol específico
        user = await _authService.registerUserWithRole(
          email: email,
          password: password,
          role: widget.role!,
          officeId: widget.officeId,
          officeName:
              widget.role == 'owner' ? _officeNameController.text.trim() : null,
          displayName: displayName,
        );
      }

      if (user != null && mounted) {
        Navigator.pop(context, user);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _officeNameController.dispose();
    super.dispose();
  }
}
