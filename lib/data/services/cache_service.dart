import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bano_model.dart';
import '../models/puerta_model.dart';


class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Keys para SharedPreferences - Baños
  static const String _banosKey = 'cached_banos';
  static const String _banosTimestampKey = 'cached_banos_timestamp';

  // Keys para SharedPreferences - Puertas 
  static const String _puertasKey = 'cached_puertas';
  static const String _puertasTimestampKey = 'cached_puertas_timestamp';

  // Tiempo de expiración del cache (24 horas por defecto)
  static const int defaultExpirationHours = 24;

  Future<void> cacheBanos(List<BanoModel> banos) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final banosJsonList = banos
          .map((bano) => {
                'id': bano.id,
                'codigo': bano.codigo,
                'nombre': bano.nombre,
                'piso': bano.piso,
                'coordenada_lat': bano.coordenadaLat,
                'coordenada_lng': bano.coordenadaLng,
                'genero': bano.genero,
                'accesibilidad': bano.accesibilidad ? '1' : '0',
                'estado': bano.estado,
                'facultad_nombre': bano.facultadNombre,
              })
          .toList();

      final jsonString = jsonEncode(banosJsonList);

      await prefs.setString(_banosKey, jsonString);
      await prefs.setInt(
          _banosTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('💾 Cache baños guardado: ${banos.length}');
    } catch (e) {
      print('❌ Error guardando cache baños: $e');
    }
  }

  Future<List<BanoModel>?> getCachedBanos(
      {bool ignoreExpiration = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonString = prefs.getString(_banosKey);
      if (jsonString == null) {
        print('📭 No hay cache de baños');
        return null;
      }

      if (!ignoreExpiration && await _isCacheExpired(_banosTimestampKey)) {
        print('⏰ Cache baños expirado');
        return null;
      }

      final List<dynamic> banosJsonList = jsonDecode(jsonString);
      final banos =
          banosJsonList.map((json) => BanoModel.fromJson(json)).toList();

      print('📦 Cache baños cargado: ${banos.length}');
      return banos;
    } catch (e) {
      print('❌ Error leyendo cache baños: $e');
      return null;
    }
  }

  Future<bool> isCacheExpired() async {
    return await _isCacheExpired(_banosTimestampKey);
  }

  Future<DateTime?> getLastCacheDate() async {
    return await _getLastCacheDate(_banosTimestampKey);
  }

  Future<void> clearBanosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_banosKey);
      await prefs.remove(_banosTimestampKey);
      print('🗑️ Cache de baños eliminado');
    } catch (e) {
      print('❌ Error limpiando cache baños: $e');
    }
  }

  Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_banosKey);
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.containsKey(_banosKey);
    final timestamp = prefs.getInt(_banosTimestampKey);
    final isExpired = await isCacheExpired();

    DateTime? cacheDate;
    if (timestamp != null) {
      cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return {
      'hasData': hasData,
      'cacheDate': cacheDate,
      'isExpired': isExpired,
      'expirationHours': defaultExpirationHours,
    };
  }

  /// Guarda la lista de puertas en cache local
  Future<void> cachePuertas(List<PuertaModel> puertas) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final puertasJsonList = puertas.map((puerta) => puerta.toJson()).toList();

      final jsonString = jsonEncode(puertasJsonList);

      await prefs.setString(_puertasKey, jsonString);
      await prefs.setInt(
          _puertasTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('💾 Cache puertas guardado: ${puertas.length}');
    } catch (e) {
      print('❌ Error guardando cache puertas: $e');
    }
  }

  /// Obtiene la lista de puertas desde cache local
  Future<List<PuertaModel>?> getCachedPuertas(
      {bool ignoreExpiration = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonString = prefs.getString(_puertasKey);
      if (jsonString == null) {
        print('📭 No hay cache de puertas');
        return null;
      }

      if (!ignoreExpiration && await _isCacheExpired(_puertasTimestampKey)) {
        print('⏰ Cache puertas expirado');
        return null;
      }

      final List<dynamic> puertasJsonList = jsonDecode(jsonString);
      final puertas =
          puertasJsonList.map((json) => PuertaModel.fromJson(json)).toList();

      print('📦 Cache puertas cargado: ${puertas.length}');
      return puertas;
    } catch (e) {
      print('❌ Error leyendo cache puertas: $e');
      return null;
    }
  }

  /// Limpia el cache de puertas
  Future<void> clearPuertasCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_puertasKey);
      await prefs.remove(_puertasTimestampKey);
      print('🗑️ Cache de puertas eliminado');
    } catch (e) {
      print('❌ Error limpiando cache puertas: $e');
    }
  }

  /// Verifica si hay puertas en cache
  Future<bool> hasCachedPuertas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_puertasKey);
  }

  Future<bool> _isCacheExpired(String timestampKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(timestampKey);

      if (timestamp == null) return true;

      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheDate);

      return difference.inHours >= defaultExpirationHours;
    } catch (e) {
      return true;
    }
  }

  Future<DateTime?> _getLastCacheDate(String timestampKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(timestampKey);

      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Limpia TODO el cache (baños y puertas)
  Future<void> clearAllCache() async {
    await clearBanosCache();
    await clearPuertasCache();
    print('🗑️ Todo el cache eliminado');
  }
}
