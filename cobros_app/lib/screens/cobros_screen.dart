import 'package:flutter/material.dart';
import '../Models/cobro_model.dart';
import 'nuevo_cobro_screen.dart';

class CobrosScreen extends StatefulWidget {
  const CobrosScreen({super.key});

  @override
  State<CobrosScreen> createState() => _CobrosScreenState();
}

class _CobrosScreenState extends State<CobrosScreen> {
  final List<Cobro> _cobros = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de cobros')),
      body:
          _cobros.isEmpty
              ? const Center(child: Text('No hay cobros registrados'))
              : ListView.builder(
                itemCount: _cobros.length,
                itemBuilder: (context, index) {
                  final cobro = _cobros[index];
                  return Dismissible(
                    key: Key(
                      '${cobro.fecha.millisecondsSinceEpoch}_${cobro.cliente.hashCode}_${cobro.monto.hashCode}',
                    ),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      final bool? confirmado = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Confirmar eliminación'),
                              content: Text(
                                '¿Eliminar cobro de ${cobro.cliente} por \$${cobro.monto.toStringAsFixed(2)}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                      return confirmado ?? false;
                    },
                    onDismissed: (direction) {
                      setState(() {
                        final cobroEliminado = _cobros.removeAt(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cobro de ${cobroEliminado.cliente} eliminado',
                            ),
                            action: SnackBarAction(
                              label: 'Deshacer',
                              onPressed: () {
                                setState(() {
                                  _cobros.insert(index, cobroEliminado);
                                });
                              },
                            ),
                          ),
                        );
                      });
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.payment, color: Colors.blue),
                        title: Text(cobro.cliente),
                        subtitle: Text('Fecha: ${_formatFecha(cobro.fecha)}'),
                        trailing: Text(
                          '\$${cobro.monto.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioCobro(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  void _mostrarFormularioCobro(BuildContext context) async {
    final nuevoCobro = await Navigator.push<Cobro>(
      context,
      MaterialPageRoute(
        builder:
            (context) => NuevoCobroScreen(
              onCobroCreado: (cobro) {
                Navigator.pop(context, cobro);
              },
            ),
      ),
    );

    if (nuevoCobro != null) {
      setState(() {
        _cobros.add(nuevoCobro);
      });
    }
  }
}
