library;

class PuertaModel {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final double coordenadaLat;
  final double coordenadaLng;
  final String estado; // 'abierta' o 'cerrada'
  final String? horarioApertura;
  final String? horarioCierre;
  final bool esPrincipal;

  PuertaModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.coordenadaLat,
    required this.coordenadaLng,
    required this.estado,
    this.horarioApertura,
    this.horarioCierre,
    required this.esPrincipal,
  });

  factory PuertaModel.fromJson(Map<String, dynamic> json) {
    return PuertaModel(
      id: int.parse(json['id'].toString()),
      codigo: json['codigo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      coordenadaLat: double.parse(json['coordenada_lat'].toString()),
      coordenadaLng: double.parse(json['coordenada_lng'].toString()),
      estado: json['estado'],
      horarioApertura: json['horario_apertura'],
      horarioCierre: json['horario_cierre'],
      esPrincipal: json['es_principal'].toString() == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'coordenada_lat': coordenadaLat,
      'coordenada_lng': coordenadaLng,
      'estado': estado,
      'horario_apertura': horarioApertura,
      'horario_cierre': horarioCierre,
      'es_principal': esPrincipal ? '1' : '0',
    };
  }

  /// Verifica si la puerta está abierta
  bool get isOpen => estado == 'abierta';

  /// Formato del horario para mostrar
  String get horarioFormatted {
    if (horarioApertura == null || horarioCierre == null) {
      return 'Horario no definido';
    }
    final apertura = horarioApertura!.length > 5
        ? horarioApertura!.substring(0, 5)
        : horarioApertura!;
    final cierre = horarioCierre!.length > 5
        ? horarioCierre!.substring(0, 5)
        : horarioCierre!;
    return '$apertura - $cierre';
  }
}
