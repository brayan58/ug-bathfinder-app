class UserModel {
  final int id;
  final String email;
  final String? nombreCompleto;
  final String rol;
  
  UserModel({
    required this.id,
    required this.email,
    this.nombreCompleto,
    required this.rol,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      email: json['email'],
      nombreCompleto: json['nombre_completo'],
      rol: json['rol'],
    );
  }
}