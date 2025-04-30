import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home,
            size: 100,
            color: Color.fromARGB(255, 17, 0, 255),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenido a la App de Cobros',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Aquí se puede agregar la lógica para crear un nuevo cobro
            },
            child: const Text('Nuevo Cobro'),
          ),
        ],
      ),
    );
  }
}
