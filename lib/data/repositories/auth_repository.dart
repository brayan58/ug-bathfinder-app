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
      print('📴 Login fallido: Sin conexión a internet');
      return {
        'success': false, 
        'error': 'Sin conexión a internet.\n\nVerifica tu WiFi o datos móviles e intenta de nuevo.',
        'isConnectionError': true,
      };
    } on ConnectionTimeoutException catch (_) {
      print('⏰ Login fallido: Timeout');
      return {
        'success': false, 
        'error': 'El servidor tardó demasiado en responder.\n\nIntenta de nuevo en unos momentos.',
        'isConnectionError': true,
      };
    } on DioException catch (e) {
      print('❌ Error Dio en login: ${e.type}');
      if (e.response != null) {
        // AQUÍ CAPTURAMOS SI EL ESTADO ES "pending_verification" (Viene en un error 403 desde PHP)
        return {
          'success': false, 
          'error': e.response!.data['error'] ?? 'Error del servidor',
          'status': e.response!.data['status'], 
          'email': e.response!.data['email'],
        };
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


  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
     
      final response = await _apiService.post(
        ApiConstants.register, 
        {
          'nombre_completo': nombre,
          'email': email,
          'password': password
        },
      );
      
      
      if (response.statusCode == 201 || response.data['success'] == true) {
        return {
          'success': true,
          'status': response.data['status'],
          'email': response.data['email'],
          'message': response.data['message'],
        };
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Error en el registro'};
      }
    } on NoConnectionException catch (_) {
      return {'success': false, 'error': 'Sin conexión a internet.', 'isConnectionError': true};
    } on ConnectionTimeoutException catch (_) {
      return {'success': false, 'error': 'El servidor tardó demasiado.', 'isConnectionError': true};
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false, 
          'error': e.response!.data['error'] ?? e.response!.data['message'] ?? 'Error del servidor',
          'status': e.response!.data['status']
        };
      } else {
        return {'success': false, 'error': 'Error de conexión.', 'isConnectionError': true};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado: $e'};
    }
  }

//verificar código de activación
  Future<Map<String, dynamic>> verifyCode(String email, String codigo) async {
    try {
      final response = await _apiService.post(
        ApiConstants.verifyCode,
        {
          'email': email,
          'codigo': codigo
        },
      );

      if (response.data['success'] == true) {
        final token = response.data['token'];
        final user = UserModel.fromJson(response.data['user']);

        // Como ya verificó exitosamente, guardamos el token y lo dejamos logueado
        await _apiService.saveToken(token);

        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Código incorrecto'};
      }
    } on NoConnectionException catch (_) {
      return {'success': false, 'error': 'Sin conexión a internet.', 'isConnectionError': true};
    } on ConnectionTimeoutException catch (_) {
      return {'success': false, 'error': 'El servidor tardó demasiado.', 'isConnectionError': true};
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'error': e.response!.data['error'] ?? 'Error al verificar'};
      } else {
        return {'success': false, 'error': 'Error de conexión.', 'isConnectionError': true};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado: $e'};
    }
  }
  

  Future<void> logout() async {
    print('👋 Cerrando sesión...');
    await _apiService.clearToken();
  }
}