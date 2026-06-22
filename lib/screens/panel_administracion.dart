import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PanelAdministracionComunidad extends StatefulWidget {
  const PanelAdministracionComunidad({super.key});

  @override
  State<PanelAdministracionComunidad> createState() =>
      _PanelAdministracionComunidadState();
}

class _PanelAdministracionComunidadState
    extends State<PanelAdministracionComunidad> {
  List<Map<String, dynamic>> _pendientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
  }

  Future<void> _cargarPendientes() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('recursos_comunitarios')
          .select()
          .eq('estado', 'propuesto')
          .order('fecha_registro', ascending: false);

      setState(() {
        _pendientes = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al cargar: $e');
    }
  }

  Future<void> _aprobarRecurso(String id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('recursos_comunitarios')
          .update({'estado': 'aprobado'})
          .eq('id', id);

      setState(() {
        _pendientes.removeWhere((r) => r['id'] == id);
      });

      _mostrarExito('✅ Recurso aprobado');
    } catch (e) {
      _mostrarError('Error al aprobar: $e');
    }
  }

  Future<void> _rechazarRecurso(String id, String motivo) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('recursos_comunitarios').update({
        'estado': 'rechazado',
        'motivo_rechazo': motivo,
      }).eq('id', id);

      setState(() {
        _pendientes.removeWhere((r) => r['id'] == id);
      });

      _mostrarExito('❌ Recurso rechazado');
    } catch (e) {
      _mostrarError('Error al rechazar: $e');
    }
  }

  void _mostrarDialogoRechazo(String id) {
    final motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Recurso'),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            hintText: 'Motivo del rechazo...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _rechazarRecurso(id, motivoController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Recursos'),
        backgroundColor: Colors.teal,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _pendientes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 80, color: Colors.green),
                      SizedBox(height: 20),
                      Text(
                        'No hay recursos pendientes',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _pendientes.length,
                  itemBuilder: (context, index) {
                    final recurso = _pendientes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.place,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recurso['nombre'] ?? 'Sin nombre',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(recurso['tipo'] ?? ''),
                                  backgroundColor: Colors.orange.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(recurso['descripcion'] ?? ''),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'ID: ${recurso['usuario_id']?.substring(0, 8)}...',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 15),
                                Icon(Icons.calendar_today,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatearFecha(recurso['fecha_registro']),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            if (recurso['foto_url'] != null) ...[
                              const SizedBox(height: 8),
                              Image.network(
                                recurso['foto_url'],
                                height: 100,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ],
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _aprobarRecurso(recurso['id']),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Aprobar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _mostrarDialogoRechazo(recurso['id']),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Rechazar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatearFecha(String? fechaStr) {
    if (fechaStr == null) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(fechaStr);
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (e) {
      return fechaStr;
    }
  }
}
