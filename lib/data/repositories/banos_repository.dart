import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../models/bano_model.dart';
import '../../core/constants/api_constants.dart';


/// Estrategia de cache:
/// 1. Intenta obtener datos del servidor
/// 2. Si tiene éxito, guarda en cache y retorna
/// 3. Si falla, intenta cargar desde cache local
/// 4. Si no hay cache, lanza excepción con mensaje amigable
class BanosRepository {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  
  // Estado para saber si los datos vienen de cache
  bool _isFromCache = false;
  DateTime? _lastServerUpdate;
  
  bool get isDataFromCache => _isFromCache;
  DateTime? get lastServerUpdate => _lastServerUpdate;

  /// Obtiene la lista de baños (con soporte offline)
  /// 
  /// Retorna:
  /// - Datos del servidor si hay conexión
  /// - Datos del cache si no hay conexión
  /// - Error amigable si no hay ninguno de los dos
  Future<BanosResult> getBanos() async {
    try {
      // Asegurar que el servicio esté inicializado
      await _apiService.init();
      
      print('🔄 Intentando obtener baños del servidor...');
      
      // Intentar obtener del servidor
      final response = await _apiService.get(ApiConstants.getBanos);
      
      if (response.data['success'] == true) {
        final List<dynamic> banosJson = response.data['data'];
        final banos = banosJson.map((json) => BanoModel.fromJson(json)).toList();
        
        print('✅ Baños obtenidos del servidor: ${banos.length}');
        
        // Guardar en cache para uso offline
        await _cacheService.cacheBanos(banos);
        
        _isFromCache = false;
        _lastServerUpdate = DateTime.now();
        
        return BanosResult(
          banos: banos,
          isFromCache: false,
          message: null,
        );
      } else {
        throw Exception(response.data['error'] ?? 'Error desconocido del servidor');
      }
      
    } on NoConnectionException catch (e) {
      print('📴 Sin conexión: $e');
      return await _loadFromCacheWithMessage(
        'Sin conexión a internet.\nMostrando datos guardados.',
      );
      
    } on ConnectionTimeoutException catch (e) {
      print('⏰ Timeout: $e');
      return await _loadFromCacheWithMessage(
        'El servidor tardó demasiado.\nMostrando datos guardados.',
      );
      
    } catch (e) {
      print('❌ Error general: $e');
      return await _loadFromCacheWithMessage(
        'Error de conexión.\nMostrando datos guardados.',
      );
    }
  }

  /// Carga datos desde cache con un mensaje informativo
  Future<BanosResult> _loadFromCacheWithMessage(String connectionMessage) async {
    try {
      // Intentar cargar desde cache (ignorando expiración en modo offline)
      final cachedBanos = await _cacheService.getCachedBanos(ignoreExpiration: true);
      
      if (cachedBanos != null && cachedBanos.isNotEmpty) {
        final lastCacheDate = await _cacheService.getLastCacheDate();
        
        _isFromCache = true;
        
        String cacheInfo = '';
        if (lastCacheDate != null) {
          final difference = DateTime.now().difference(lastCacheDate);
          if (difference.inMinutes < 60) {
            cacheInfo = '\nÚltima actualización: hace ${difference.inMinutes} minutos';
          } else if (difference.inHours < 24) {
            cacheInfo = '\nÚltima actualización: hace ${difference.inHours} horas';
          } else {
            cacheInfo = '\nÚltima actualización: hace ${difference.inDays} días';
          }
        }
        
        print('📦 Datos cargados desde cache: ${cachedBanos.length} baños');
        
        return BanosResult(
          banos: cachedBanos,
          isFromCache: true,
          message: '$connectionMessage$cacheInfo',
        );
      } else {
        // No hay cache disponible
        print('📭 No hay datos en cache');
        throw NoCacheDataException(
          'No hay conexión a internet y no hay datos guardados.\n\n'
          'Por favor, conéctate a internet para cargar los baños por primera vez.',
        );
      }
    } catch (e) {
      if (e is NoCacheDataException) {
        rethrow;
      }
      throw NoCacheDataException(
        'No hay conexión a internet y no hay datos guardados.\n\n'
        'Por favor, conéctate a internet para cargar los baños por primera vez.',
      );
    }
  }

  /// Fuerza la actualización desde el servidor (ignora cache)
  Future<BanosResult> forceRefresh() async {
    try {
      await _apiService.init();
      
      final hasConnection = await _apiService.hasConnection;
      if (!hasConnection) {
        throw NoConnectionException('Sin conexión a internet');
      }
      
      final response = await _apiService.get(ApiConstants.getBanos);
      
      if (response.data['success'] == true) {
        final List<dynamic> banosJson = response.data['data'];
        final banos = banosJson.map((json) => BanoModel.fromJson(json)).toList();
        
        await _cacheService.cacheBanos(banos);
        
        _isFromCache = false;
        _lastServerUpdate = DateTime.now();
        
        return BanosResult(
          banos: banos,
          isFromCache: false,
          message: 'Datos actualizados correctamente',
        );
      } else {
        throw Exception(response.data['error']);
      }
    } on NoConnectionException {
      rethrow;
    } catch (e) {
      throw Exception('Error al actualizar: $e');
    }
  }

  /// Limpia el cache local
  Future<void> clearCache() async {
    await _cacheService.clearBanosCache();
  }

  /// Obtiene información del estado del cache
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await _cacheService.getCacheInfo();
  }
}

/// Resultado de la operación getBanos con metadatos
class BanosResult {
  final List<BanoModel> banos;
  final bool isFromCache;
  final String? message;
  
  BanosResult({
    required this.banos,
    required this.isFromCache,
    this.message,
  });
}

/// Excepción cuando no hay datos en cache y no hay conexión
class NoCacheDataException implements Exception {
  final String message;
  NoCacheDataException(this.message);
  
  @override
  String toString() => message;
}