import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/reporte_model.dart';
import '../../core/constants/api_constants.dart';


class ReportesRepository {
  final ApiService _apiService = ApiService();

  /// Crea un nuevo reporte
  /// Requiere conexión a internet
  Future<Map<String, dynamic>> createReporte({
    required int banoId,
    required String tipo,
    required String urgencia,
    String? descripcion,
  }) async {
    try {
      await _apiService.init();

      print('📝 Creando reporte para baño ID: $banoId');

      final response = await _apiService.post(
        ApiConstants.createReporte,
        {
          'bano_id': banoId,
          'tipo': tipo,
          'urgencia': urgencia,
          'descripcion': descripcion,
        },
      );

      print('✅ Reporte creado: ${response.statusCode}');

      if (response.data['success'] == true) {
        return {'success': true, 'message': response.data['message']};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Error desconocido'};
      }
    } on NoConnectionException catch (_) {
      print('📴 Sin conexión al crear reporte');
      return {
        'success': false,
        'error': 'Sin conexión a internet.\n\nConéctate a una red WiFi o datos móviles para enviar el reporte.',
        'isConnectionError': true,
      };
    } on ConnectionTimeoutException catch (_) {
      print('⏰ Timeout al crear reporte');
      return {
        'success': false,
        'error': 'El servidor tardó demasiado en responder.\n\nIntenta de nuevo en unos momentos.',
        'isConnectionError': true,
      };
    } on DioException catch (e) {
      print('❌ Error Dio al crear reporte: ${e.response?.statusCode}');
      if (e.response != null) {
        return {
          'success': false,
          'error': e.response!.data['error'] ?? 'Error del servidor'
        };
      } else {
        return {
          'success': false,
          'error': 'Error de conexión. Verifica tu internet.',
          'isConnectionError': true,
        };
      }
    } catch (e) {
      print('❌ Error inesperado: $e');
      return {'success': false, 'error': 'Error inesperado: $e'};
    }
  }

  /// Obtiene los reportes del usuario actual
  Future<ReportesResult> getMyReportes() async {
    try {
      await _apiService.init();

      final response = await _apiService.get(ApiConstants.getMyReportes);

      if (response.data['success'] == true) {
        final List<dynamic> reportesJson = response.data['data'];
        final reportes = reportesJson.map((json) => ReporteModel.fromJson(json)).toList();
        
        print('📋 Reportes obtenidos: ${reportes.length}');
        
        return ReportesResult(
          reportes: reportes,
          isSuccess: true,
          message: null,
        );
      } else {
        return ReportesResult(
          reportes: [],
          isSuccess: false,
          message: response.data['error'] ?? 'Error al obtener reportes',
        );
      }
    } on NoConnectionException catch (_) {
      print('📴 Sin conexión al obtener reportes');
      return ReportesResult(
        reportes: [],
        isSuccess: false,
        message: 'Sin conexión a internet.\n\nConéctate para ver tus reportes.',
        isConnectionError: true,
      );
    } on ConnectionTimeoutException catch (_) {
      print('⏰ Timeout al obtener reportes');
      return ReportesResult(
        reportes: [],
        isSuccess: false,
        message: 'El servidor tardó demasiado.\n\nIntenta de nuevo.',
        isConnectionError: true,
      );
    } catch (e) {
      print('❌ Error en getMyReportes: $e');
      return ReportesResult(
        reportes: [],
        isSuccess: false,
        message: 'Error de conexión: $e',
        isConnectionError: true,
      );
    }
  }
}

/// Resultado de la operación getMyReportes
class ReportesResult {
  final List<ReporteModel> reportes;
  final bool isSuccess;
  final String? message;
  final bool isConnectionError;
  
  ReportesResult({
    required this.reportes,
    required this.isSuccess,
    this.message,
    this.isConnectionError = false,
  });
}