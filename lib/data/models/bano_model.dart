class BanoModel {
  final int id;
  final String codigo;
  final String nombre;
  final String piso;
  final double coordenadaLat;
  final double coordenadaLng;
  final String genero;
  final bool accesibilidad;
  final String estado;
  final String? facultadNombre;
  
  BanoModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.piso,
    required this.coordenadaLat,
    required this.coordenadaLng,
    required this.genero,
    required this.accesibilidad,
    required this.estado,
    this.facultadNombre,
  });
  
  factory BanoModel.fromJson(Map<String, dynamic> json) {
    return BanoModel(
      id: int.parse(json['id'].toString()),
      codigo: json['codigo'],
      nombre: json['nombre'],
      piso: json['piso'],
      coordenadaLat: double.parse(json['coordenada_lat'].toString()),
      coordenadaLng: double.parse(json['coordenada_lng'].toString()),
      genero: json['genero'],
      accesibilidad: json['accesibilidad'].toString() == '1',
      estado: json['estado'],
      facultadNombre: json['facultad_nombre'],
    );
  }
}