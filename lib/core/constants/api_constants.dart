import '../config/env_config.dart';

class ApiConstants {
  static const String baseUrl = EnvConfig.baseUrl;

  // Auth endpoints
  static const String register = '$baseUrl/auth/register.php';
  static const String login = '$baseUrl/auth/login.php';

  // Baños endpoints
  static const String getBanos = '$baseUrl/banos/get_all.php';
  static const String getBanoById = '$baseUrl/banos/get_by_id.php';

  //   // Puertas endpoints
  static const String getPuertas = '$baseUrl/puertas/get_all.php';
  static const String updatePuertaEstado = '$baseUrl/puertas/update_estado.php';

  // Reportes endpoints
  static const String createReporte = '$baseUrl/reportes/create.php';
  static const String getMyReportes = '$baseUrl/reportes/get_by_user.php';
}










// class ApiConstants {
//  static const String baseUrl = 'http://10.0.2.2/ug-bathfinder/api/v1';
  
//   // Auth endpoints
//   static const String register = '$baseUrl/auth/register.php';
//   static const String login = '$baseUrl/auth/login.php';
  
//   // Baños endpoints
//   static const String getBanos = '$baseUrl/banos/get_all.php';
//   static const String getBanoById = '$baseUrl/banos/get_by_id.php';
  
//   // Puertas endpoints 
//   static const String getPuertas = '$baseUrl/puertas/get_all.php';
//   static const String updatePuertaEstado = '$baseUrl/puertas/update_estado.php';
  
//   // Reportes endpoints
//   static const String createReporte = '$baseUrl/reportes/create.php';
//   static const String getMyReportes = '$baseUrl/reportes/get_by_user.php';
// }