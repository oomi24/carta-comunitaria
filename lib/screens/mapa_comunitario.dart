import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapaComunitario extends StatefulWidget {
  const MapaComunitario({super.key});

  @override
  State<MapaComunitario> createState() => _MapaComunitarioState();
}

class _MapaComunitarioState extends State<MapaComunitario> {
  late GoogleMapController _mapController;
  final Set<Marker> _marcadores = {};
  String _filtroTipo = 'todos';
  bool _cargando = true;

  final Map<String, Color> _coloresTipo = {
    'infraestructura': Colors.blue,
    'recurso': Colors.green,
    'problema': Colors.red,
    'proyecto': Colors.orange,
  };

  final Map<String, String> _nombresTipo = {
    'todos': 'Todos',
    'infraestructura': 'Infraestructura',
    'recurso': 'Recursos Naturales',
    'problema': 'Problemas',
    'proyecto': 'Proyectos',
  };

  @override
  void initState() {
    super.initState();
    _cargarRecursos();
  }

  Future<void> _cargarRecursos() async {
    try {
      final supabase = Supabase.instance.client;
      
      var query = supabase
          .from('recursos_comunitarios')
          .select()
          .eq('estado', 'aprobado');

      if (_filtroTipo != 'todos') {
        query = query.eq('tipo', _filtroTipo);
      }

      final data = await query;

      final markers = <Marker>{};
      
      for (var recurso in data) {
        final id = recurso['id'].toString();
        final lat = recurso['latitud'] as double;
        final lng = recurso['longitud'] as double;
        final tipo = recurso['tipo'] as String;

        markers.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: recurso['nombre'],
              snippet: recurso['descripcion'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _coloresTipo[tipo]?.hue ?? 0,
            ),
          ),
        );
      }

      setState(() {
        _marcadores.clear();
        _marcadores.addAll(markers);
        _cargando = false;
      });

    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mapa: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Comunitario'),
        backgroundColor: Colors.teal,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filtroTipo = value;
                _cargando = true;
                _cargarRecursos();
              });
            },
            itemBuilder: (context) => _nombresTipo.entries.map((entry) {
              return PopupMenuItem(
                value: entry.key,
                child: Row(
                  children: [
                    if (entry.key != 'todos')
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _coloresTipo[entry.key],
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(entry.value),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_cargando)
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(10.4806, -66.9036), // Caracas
                zoom: 12,
              ),
              markers: _marcadores,
              onMapCreated: (controller) => _mapController = controller,
            ),
          if (_cargando)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black26),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leyenda:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  ..._coloresTipo.entries.map((entry) {
                    return Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: entry.value,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(_nombresTipo[entry.key] ?? entry.key),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
