import 'package:flutter/material.dart';
import '../Models/cobro_model.dart';

class NuevoCobroScreen extends StatefulWidget {
  final Function(Cobro) onCobroCreado;

  const NuevoCobroScreen({super.key, required this.onCobroCreado});

  @override
  State<NuevoCobroScreen> createState() => _NuevoCobroScreenState();
}

class _NuevoCobroScreenState extends State<NuevoCobroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _montoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Cobro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _clienteController,
                decoration: const InputDecoration(labelText: 'Cliente'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre del cliente';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un numero valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarCobro,
                child: const Text('Guardar Cobro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardarCobro() {
    if (_formKey.currentState!.validate()) {
      final nuevoCobro = Cobro(
        cliente: _clienteController.text,
        monto: double.parse(_montoController.text),
        fecha: DateTime.now(),
      );

      widget.onCobroCreado(nuevoCobro);
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _montoController.dispose();
    super.dispose();
  }
}
