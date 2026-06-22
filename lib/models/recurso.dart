class RecursoComunitario {
  final String id;
  final String nombre;
  final String tipo; // 'infraestructura', 'recurso', 'problema', 'proyecto'
  final String descripcion;
  final double latitud;
  final double longitud;
  final String direccion;
  final String? fotoUrl;
  final String estado; // 'propuesto', 'verificado', 'aprobado'
  final String usuarioId;
  final DateTime fechaRegistro;
  final Map<String, dynamic>? atributosExtra;
  final List<String>? comentarios;

  RecursoComunitario({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.direccion,
    this.fotoUrl,
    this.estado = 'propuesto',
    required this.usuarioId,
    required this.fechaRegistro,
    this.atributosExtra,
    this.comentarios,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'foto_url': fotoUrl,
      'estado': estado,
      'usuario_id': usuarioId,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'atributos_extra': atributosExtra,
      'comentarios': comentarios,
    };
  }

  factory RecursoComunitario.fromMap(String id, Map<String, dynamic> map) {
    return RecursoComunitario(
      id: id,
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] ?? 'infraestructura',
      descripcion: map['descripcion'] ?? '',
      latitud: map['latitud'] ?? 0.0,
      longitud: map['longitud'] ?? 0.0,
      direccion: map['direccion'] ?? '',
      fotoUrl: map['foto_url'],
      estado: map['estado'] ?? 'propuesto',
      usuarioId: map['usuario_id'] ?? '',
      fechaRegistro: DateTime.parse(map['fecha_registro'] ?? DateTime.now().toIso8601String()),
      atributosExtra: map['atributos_extra'],
      comentarios: List<String>.from(map['comentarios'] ?? []),
    );
  }
}
