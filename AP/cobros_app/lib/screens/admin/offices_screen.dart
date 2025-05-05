import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfficesScreen extends StatefulWidget {
  const OfficesScreen({super.key});

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Oficinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOfficeDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('offices').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay oficinas registradas'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final office = snapshot.data!.docs[index];
              return Card(
                child: ListTile(
                  title: Text(office['name']),
                  subtitle: Text(office['address']),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditOfficeDialog(office),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddOfficeDialog() {
    _nameController.clear();
    _addressController.clear();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Agregar Nueva Oficina'),
            content: _buildOfficeForm(),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _saveOffice,
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _showEditOfficeDialog(DocumentSnapshot office) {
    _nameController.text = office['name'];
    _addressController.text = office['address'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Oficina'),
            content: _buildOfficeForm(),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => _saveOffice(officeId: office.id),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Widget _buildOfficeForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Oficina',
            ),
            validator: (value) => value!.isEmpty ? 'Requerido' : null,
          ),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Dirección'),
            validator: (value) => value!.isEmpty ? 'Requerido' : null,
          ),
        ],
      ),
    );
  }

  Future<void> _saveOffice({String? officeId}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final officeData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (officeId == null) {
        // Nueva oficina
        officeData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('offices').add(officeData);
      } else {
        // Editar oficina existente
        await _firestore.collection('offices').doc(officeId).update(officeData);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
