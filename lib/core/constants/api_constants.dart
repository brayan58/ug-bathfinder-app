import '../config/env_config.dart';

class ApiConstants {
  // Usar la URL del archivo de configuración
  static String get baseUrl => EnvConfig.baseUrl;
  
  // Auth endpoints
  static String get register => '$baseUrl/auth/register.php';
  static String get login => '$baseUrl/auth/login.php';
  
  // Baños endpoints
  static String get getBanos => '$baseUrl/banos/get_all.php';
  static String get getBanoById => '$baseUrl/banos/get_by_id.php';
  
  // Puertas endpoints 
  static String get getPuertas => '$baseUrl/puertas/get_all.php';
  
  // Reportes endpoints
  static String get createReporte => '$baseUrl/reportes/create.php';
  static String get getMyReportes => '$baseUrl/reportes/get_by_user.php';
}



