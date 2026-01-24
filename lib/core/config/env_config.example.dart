/// Archivo de ejemplo para configuración de entorno

/// INSTRUCCIONES:
/// 1. Copiar este archivo y renombrarlo a 'env_config.dart'
/// 2. Reemplazar los valores con tus API keys reales
/// 3. El archivo env_config.dart NO se sube a Git (está en .gitignore)

class EnvConfig {
  // Obtener en: https://console.cloud.google.com/
  static const String googleMapsApiKey = 'TU_GOOGLE_MAPS_API_KEY';
  
  // URL del backend
  // Emulador Android: 'http://10.0.2.2/ug-bathfinder/api/v1'
  // Dispositivo físico en misma red: 'http://192.x.x.x/ug-bathfinder/api/v1'
  // Producción: 'https://tu-dominio.com/api/v1'
  static const String baseUrl = 'http://10.0.2.2/ug-bathfinder/api/v1';
}