import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterCollectorScreen extends StatefulWidget {
  final String officeId;

  const RegisterCollectorScreen({super.key, required this.officeId});

  @override
  State<RegisterCollectorScreen> createState() =>
      _RegisterCollectorScreenState();
}

class _RegisterCollectorScreenState extends State<RegisterCollectorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Nuevo Cobrador')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
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
                    (value) =>
                        value!.length >= 6 ? null : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _registerCollector,
                    child: const Text('Registrar Cobrador'),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerCollector() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      final user = await authService.registerCollector(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        officeId: widget.officeId,
        displayName: _nameController.text.trim(),
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cobrador registrado exitosamente')),
        );
        Navigator.pop(context);
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
