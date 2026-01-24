import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        {'email': email, 'password': password},
      );
      
      if (response.data['success'] == true) {
        final token = response.data['token'];
        final user = UserModel.fromJson(response.data['user']);
        
        // Guardar token
        await _apiService.saveToken(token);
        
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Error desconocido'};
      }
    } on NoConnectionException catch (_) {
      // Error de conexión después de reintentos
      print('📴 Login fallido: Sin conexión a internet');
      return {
        'success': false, 
        'error': 'Sin conexión a internet.\n\nVerifica tu WiFi o datos móviles e intenta de nuevo.',
        'isConnectionError': true,
      };
    } on ConnectionTimeoutException catch (_) {
      // Timeout después de reintentos
      print('⏰ Login fallido: Timeout');
      return {
        'success': false, 
        'error': 'El servidor tardó demasiado en responder.\n\nIntenta de nuevo en unos momentos.',
        'isConnectionError': true,
      };
    } on DioException catch (e) {
      print('❌ Error Dio en login: ${e.type}');
      if (e.response != null) {
        return {'success': false, 'error': e.response!.data['error'] ?? 'Error del servidor'};
      } else {
        return {
          'success': false, 
          'error': 'Error de conexión. Verifica tu internet.',
          'isConnectionError': true,
        };
      }
    } catch (e) {
      print('❌ Error inesperado en login: $e');
      return {'success': false, 'error': 'Error inesperado: $e'};
    }
  }
  
  Future<void> logout() async {
    print('👋 Cerrando sesión...');
    await _apiService.clearToken();
  }
}