import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../models/puerta_model.dart';
import '../../core/constants/api_constants.dart';


class PuertasRepository {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  
  bool _isFromCache = false;
  
  bool get isDataFromCache => _isFromCache;

  /// Obtiene la lista de puertas (con soporte offline)
  Future<PuertasResult> getPuertas() async {
    try {
      await _apiService.init();
      
      print('🚪 Intentando obtener puertas del servidor...');
      
      final response = await _apiService.get(ApiConstants.getPuertas);
      
      if (response.data['success'] == true) {
        final List<dynamic> puertasJson = response.data['data'];
        final puertas = puertasJson.map((json) => PuertaModel.fromJson(json)).toList();
        
        print('✅ Puertas obtenidas del servidor: ${puertas.length}');
        
        // Guardar en cache
        await _cacheService.cachePuertas(puertas);
        
        _isFromCache = false;
        
        return PuertasResult(
          puertas: puertas,
          isFromCache: false,
          message: null,
        );
      } else {
        throw Exception(response.data['error'] ?? 'Error desconocido del servidor');
      }
      
    } on NoConnectionException catch (e) {
      print('🔴 Sin conexión para puertas: $e');
      return await _loadFromCacheWithMessage(
        'Sin conexión. Mostrando puertas guardadas.',
      );
      
    } on ConnectionTimeoutException catch (e) {
      print('⏰ Timeout puertas: $e');
      return await _loadFromCacheWithMessage(
        'Servidor lento. Mostrando puertas guardadas.',
      );
      
    } catch (e) {
      print('❌ Error puertas: $e');
      return await _loadFromCacheWithMessage(
        'Error de conexión. Mostrando puertas guardadas.',
      );
    }
  }

  Future<PuertasResult> _loadFromCacheWithMessage(String connectionMessage) async {
    try {
      final cachedPuertas = await _cacheService.getCachedPuertas(ignoreExpiration: true);
      
      if (cachedPuertas != null && cachedPuertas.isNotEmpty) {
        _isFromCache = true;
        
        print('📦 Puertas cargadas desde cache: ${cachedPuertas.length}');
        
        return PuertasResult(
          puertas: cachedPuertas,
          isFromCache: true,
          message: connectionMessage,
        );
      } else {
        print('📭 No hay puertas en cache');
        // No lanzar excepción, devolver lista vacía
        return PuertasResult(
          puertas: [],
          isFromCache: true,
          message: 'No hay puertas guardadas.',
        );
      }
    } catch (e) {
      return PuertasResult(
        puertas: [],
        isFromCache: true,
        message: 'Error cargando puertas del cache.',
      );
    }
  }

  /// Crea un reporte de puerta cerrada
  Future<Map<String, dynamic>> reportarPuertaCerrada({
    required int puertaId,
    required String urgencia,
    String? descripcion,
  }) async {
    try {
      await _apiService.init();
      
      final response = await _apiService.post(
        ApiConstants.createReporte,
        {
          'puerta_id': puertaId,
          'tipo': 'puerta_cerrada',
          'urgencia': urgencia,
          'descripcion': descripcion,
        },
      );
      
      if (response.data['success'] == true) {
        return {'success': true, 'message': response.data['message']};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Error desconocido'};
      }
    } on NoConnectionException catch (_) {
      return {
        'success': false,
        'error': 'Sin conexión a internet.\n\nConéctate para enviar el reporte.',
        'isConnectionError': true,
      };
    } on ConnectionTimeoutException catch (_) {
      return {
        'success': false,
        'error': 'El servidor tardó demasiado.\n\nIntenta de nuevo.',
        'isConnectionError': true,
      };
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }
}

/// Resultado de la operación getPuertas
class PuertasResult {
  final List<PuertaModel> puertas;
  final bool isFromCache;
  final String? message;
  
  PuertasResult({
    required this.puertas,
    required this.isFromCache,
    this.message,
  });
}