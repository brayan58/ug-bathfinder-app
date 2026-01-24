import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';


class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  String? _token;
  bool _initialized = false;
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Configuración de reintentos
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Agregar interceptor para logging y manejo de errores
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('📤 Request: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('📥 Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error: ${error.type} - ${error.message}');
        return handler.next(error);
      },
    ));
  }
  
  Future<void> init() async {
    if (!_initialized) {
      await _loadToken();
      _initialized = true;
    }
  }
  
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }
  
  Future<void> saveToken(String token) async {
    _token = token;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
  
  Future<void> clearToken() async {
    _token = null;
    _initialized = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
  
  String? get token => _token;
  
  /// Verifica si hay conexión a internet
  Future<bool> get hasConnection => _connectivityService.hasInternetConnection();
  
  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (includeAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }
  
  /// POST con reintentos automáticos
  Future<Response> post(String url, Map<String, dynamic> data) async {
    return _executeWithRetry(() async {
      final headers = _buildHeaders(includeAuth: _token != null);
      return await _dio.post(url, data: data, options: Options(headers: headers));
    });
  }
  
  /// GET con reintentos automáticos
  Future<Response> get(String url) async {
    if (!_initialized) {
      await init();
    }
    
    if (_token == null) {
      await _loadToken();
    }
    
    return _executeWithRetry(() async {
      final headers = _buildHeaders(includeAuth: true);
      return await _dio.get(url, options: Options(headers: headers));
    });
  }
  
  /// PUT con reintentos automáticos
  Future<Response> put(String url, Map<String, dynamic> data) async {
    return _executeWithRetry(() async {
      final headers = _buildHeaders(includeAuth: true);
      return await _dio.put(url, data: data, options: Options(headers: headers));
    });
  }
  
  /// Ejecuta una petición con reintentos automáticos
  Future<Response> _executeWithRetry(Future<Response> Function() request) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        attempts++;
        print('🔄 Intento $attempts de $maxRetries');
        
        // Verificar conexión antes de intentar
        final hasInternet = await _connectivityService.hasInternetConnection();
        if (!hasInternet) {
          throw NoConnectionException('Sin conexión a internet');
        }
        
        final response = await request();
        return response;
        
      } on DioException catch (e) {
        print('⚠️ DioException en intento $attempts: ${e.type}');
        
        // Errores que NO vale la pena reintentar
        if (e.response?.statusCode == 401 || 
            e.response?.statusCode == 403 ||
            e.response?.statusCode == 404) {
          rethrow;
        }
        
        // Si es el último intento, lanzar error
        if (attempts >= maxRetries) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            throw ConnectionTimeoutException('El servidor tardó demasiado en responder');
          }
          if (e.type == DioExceptionType.connectionError) {
            throw NoConnectionException('No se pudo conectar al servidor');
          }
          rethrow;
        }
        
        // Esperar antes de reintentar
        print('⏳ Esperando ${retryDelay.inSeconds}s antes de reintentar...');
        await Future.delayed(retryDelay);
        
      } on NoConnectionException {
        if (attempts >= maxRetries) {
          rethrow;
        }
        print('⏳ Esperando ${retryDelay.inSeconds}s antes de reintentar...');
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('Se agotaron los reintentos');
  }
}

/// Excepción personalizada para cuando no hay conexión
class NoConnectionException implements Exception {
  final String message;
  NoConnectionException(this.message);
  
  @override
  String toString() => message;
}

/// Excepción personalizada para timeout de conexión
class ConnectionTimeoutException implements Exception {
  final String message;
  ConnectionTimeoutException(this.message);
  
  @override
  String toString() => message;
}