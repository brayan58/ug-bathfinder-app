library;

class ReporteModel {
  final int id;
  final String tipo;
  final String? descripcion;
  final String? urgencia; 
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaResolucion;
  final String? notaAdmin;

  // Info del baño (puede ser null si es reporte de puerta)
  final int? banoId;
  final String? banoCodigo;
  final String? banoNombre;
  final String? facultadNombre;

  // Info de la puerta (puede ser null si es reporte de baño)
  final int? puertaId;
  final String? puertaCodigo;
  final String? puertaNombre;

  // Tipo de recurso ('bano' o 'puerta')
  final String tipoRecurso;

  ReporteModel({
    required this.id,
    required this.tipo,
    this.descripcion,
    this.urgencia, 
    required this.estado,
    required this.fechaCreacion,
    this.fechaResolucion,
    this.notaAdmin,
    this.banoId,
    this.banoCodigo,
    this.banoNombre,
    this.facultadNombre,
    this.puertaId,
    this.puertaCodigo,
    this.puertaNombre,
    required this.tipoRecurso,
  });

  factory ReporteModel.fromJson(Map<String, dynamic> json) {
    // Determinar tipo de recurso
    String tipoRecurso = 'bano';
    if (json['tipo_recurso'] != null) {
      tipoRecurso = json['tipo_recurso'];
    } else if (json['puerta_id'] != null) {
      tipoRecurso = 'puerta';
    }

    return ReporteModel(
      id: int.parse(json['id'].toString()),
      tipo: json['tipo'],
      descripcion: json['descripcion'],
      urgencia: json['urgencia'], 
      estado: json['estado'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaResolucion: json['fecha_resolucion'] != null
          ? DateTime.parse(json['fecha_resolucion'])
          : null,
      notaAdmin: json['nota_admin'],
      // Info baño
      banoId: json['bano_id'] != null
          ? int.parse(json['bano_id'].toString())
          : null,
      banoCodigo: json['bano_codigo'],
      banoNombre: json['bano_nombre'],
      facultadNombre: json['facultad_nombre'] ?? json['bano_facultad_nombre'],
      // Info puerta
      puertaId: json['puerta_id'] != null
          ? int.parse(json['puerta_id'].toString())
          : null,
      puertaCodigo: json['puerta_codigo'],
      puertaNombre: json['puerta_nombre'],
      // Tipo recurso
      tipoRecurso: tipoRecurso,
    );
  }

  /// Verifica si es un reporte de puerta
  bool get isReportePuerta => tipoRecurso == 'puerta';

  /// Verifica si es un reporte de baño
  bool get isReporteBano => tipoRecurso == 'bano';

  /// Obtiene el nombre del recurso (baño o puerta)
  String get nombreRecurso {
    if (isReportePuerta) {
      return puertaNombre ?? 'Puerta desconocida';
    }
    return banoNombre ?? 'Baño desconocido';
  }

  /// Obtiene el código del recurso
  String get codigoRecurso {
    if (isReportePuerta) {
      return puertaCodigo ?? '';
    }
    return banoCodigo ?? '';
  }
  

  String get urgenciaTexto {
    if (urgencia == null || urgencia!.isEmpty) {
      return 'Sin asignar';
    }
    switch (urgencia) {
      case 'baja':
        return 'Baja';
      case 'media':
        return 'Media';
      case 'alta':
        return 'Alta';
      default:
        return urgencia!;
    }
  }
}