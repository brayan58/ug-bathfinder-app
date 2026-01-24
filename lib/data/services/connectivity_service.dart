import 'dart:async';
import 'dart:io';


class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  /// Verifica si hay conexión a internet realizando una petición real
  /// Retorna true si hay conexión, false si no
  Future<bool> hasInternetConnection() async {
    try {
      // Intentar conectar a Google DNS (confiable y rápido)
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ Conexión a internet disponible');
        return true;
      }
      return false;
    } on SocketException catch (_) {
      print('❌ Sin conexión a internet (SocketException)');
      return false;
    } on TimeoutException catch (_) {
      print('❌ Sin conexión a internet (Timeout)');
      return false;
    } catch (e) {
      print('❌ Error verificando conexión: $e');
      return false;
    }
  }

  /// Verifica si el servidor backend está disponible
  /// Útil para diferenciar entre "sin internet" y "servidor caído"
  Future<bool> isServerReachable(String baseUrl) async {
    try {
      final uri = Uri.parse(baseUrl);
      final result = await InternetAddress.lookup(uri.host)
          .timeout(const Duration(seconds: 5));
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('❌ Servidor no alcanzable: $e');
      return false;
    }
  }
}