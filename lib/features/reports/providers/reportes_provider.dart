import 'package:flutter/material.dart';
import '../../../data/repositories/reportes_repository.dart';
import '../../../data/models/reporte_model.dart';


class ReportesProvider with ChangeNotifier {
  final ReportesRepository _reportesRepository = ReportesRepository();
  
  List<ReporteModel> _reportes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isConnectionError = false;
  
  List<ReporteModel> get reportes => _reportes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConnectionError => _isConnectionError;
  
  /// Crea un nuevo reporte
  Future<bool> createReporte({
    required int banoId,
    required String tipo,
    required String urgencia,
    String? descripcion,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();
    
    final result = await _reportesRepository.createReporte(
      banoId: banoId,
      tipo: tipo,
      urgencia: urgencia,
      descripcion: descripcion,
    );
    
    _isLoading = false;
    
    if (result['success'] == true) {
      // Intentar recargar reportes (si falla, no es crítico)
      try {
        await loadMyReportes();
      } catch (_) {
        // Ignorar error al recargar
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'];
      _isConnectionError = result['isConnectionError'] == true;
      notifyListeners();
      return false;
    }
  }
  
  /// Carga los reportes del usuario
  Future<void> loadMyReportes() async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();
    
    final result = await _reportesRepository.getMyReportes();
    
    _isLoading = false;
    
    if (result.isSuccess) {
      _reportes = result.reportes;
      _errorMessage = null;
      _isConnectionError = false;
    } else {
      _errorMessage = result.message;
      _isConnectionError = result.isConnectionError;
      // Mantener reportes anteriores si los hay
    }
    
    notifyListeners();
  }
  
  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();
  }
}