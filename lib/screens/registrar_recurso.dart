import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class RegistrarRecurso extends StatefulWidget {
  const RegistrarRecurso({super.key});

  @override
  State<RegistrarRecurso> createState() => _RegistrarRecursoState();
}

class _RegistrarRecursoState extends State<RegistrarRecurso> {
  final _formKey = GlobalKey<FormState>();
  
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();
  
  String _tipoSeleccionado = 'infraestructura';
  Position? _ubicacionActual;
  File? _fotoSeleccionada;
  bool _cargando = false;
  
  final Map<String, IconData> _iconosTipo = {
    'infraestructura': Icons.business_center,
    'recurso': Icons.water_drop,
    'problema': Icons.warning_amber,
    'proyecto': Icons.handshake,
  };

  final Map<String, String> _nombresTipo = {
    'infraestructura': 'Infraestructura',
    'recurso': 'Recurso Natural',
    'problema': 'Problema',
    'proyecto': 'Proyecto Comunitario',
  };

  final Map<String, Color> _coloresTipo = {
    'infraestructura': Colors.blue,
    'recurso': Colors.green,
    'problema': Colors.red,
    'proyecto': Colors.orange,
  };

  Future<void> _obtenerUbicacion() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _ubicacionActual = pos);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Ubicación obtenida')),
      );
    } catch (e) {
      _mostrarError('No se pudo obtener GPS: $e');
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(source: ImageSource.camera);
      
      if (foto != null) {
        setState(() => _fotoSeleccionada = File(foto.path));
      }
    } catch (e) {
      _mostrarError('Error al tomar foto: $e');
    }
  }

  Future<void> _guardarRecurso() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ubicacionActual == null) {
      _mostrarError('⚠️ Debes obtener la ubicación GPS');
      return;
    }

    setState(() => _cargando = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      String? fotoUrl;
      if (_fotoSeleccionada != null) {
        final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'comunidad/${user!.id}/$nombreArchivo';
        
        await supabase.storage
            .from('fotos_comunidad')
            .upload(path, _fotoSeleccionada!.readAsBytesSync());
        
        fotoUrl = supabase.storage
            .from('fotos_comunidad')
            .getPublicUrl(path);
      }

      final recurso = {
        'nombre': _nombreController.text,
        'tipo': _tipoSeleccionado,
        'descripcion': _descripcionController.text,
        'latitud': _ubicacionActual!.latitude,
        'longitud': _ubicacionActual!.longitude,
        'direccion': _direccionController.text,
        'foto_url': fotoUrl,
        'estado': 'propuesto',
        'usuario_id': user!.id,
        'fecha_registro': DateTime.now().toIso8601String(),
        'comentarios': [],
        'votos_confirmacion': 0,
      };

      await supabase.from('recursos_comunitarios').insert(recurso);

      _mostrarExito('✅ ¡Recurso registrado exitosamente!');
      
      _nombreController.clear();
      _descripcionController.clear();
      _direccionController.clear();
      setState(() {
        _fotoSeleccionada = null;
        _ubicacionActual = null;
      });

    } catch (e) {
      _mostrarError('Error al guardar: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Recurso Comunitario'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tipo de Recurso:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _nombresTipo.keys.map((tipo) {
                  final isSelected = _tipoSeleccionado == tipo;
                  return ChoiceChip(
                    label: Text(_nombresTipo[tipo]!),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _tipoSeleccionado = tipo);
                    },
                    selectedColor: _coloresTipo[tipo]!.withOpacity(0.2),
                    avatar: Icon(
                      _iconosTipo[tipo]!,
                      color: isSelected ? _coloresTipo[tipo] : Colors.grey,
                      size: 18,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del recurso',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción detallada',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'La descripción es obligatoria' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección / Sector',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      color: _ubicacionActual != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _ubicacionActual != null
                            ? '📍 Lat: ${_ubicacionActual!.latitude}\n📍 Lon: ${_ubicacionActual!.longitude}'
                            : '📡 GPS no obtenido',
                        style: TextStyle(
                          color: _ubicacionActual != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _obtenerUbicacion,
                      icon: const Icon(Icons.gps_not_fixed),
                      label: const Text('Obtener'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _tomarFoto,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _fotoSeleccionada != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_fotoSeleccionada!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => setState(() => _fotoSeleccionada = null),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text(
                              '📸 Toca para tomar foto',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _cargando ? null : _guardarRecurso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save),
                          SizedBox(width: 8),
                          Text('Guardar Recurso'),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El registro quedará como "propuesto" hasta que un '
                        'administrador de la comunidad lo verifique.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
