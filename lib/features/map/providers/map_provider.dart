import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/repositories/banos_repository.dart';
import '../../../data/repositories/puertas_repository.dart';
import '../../../data/models/bano_model.dart';
import '../../../data/models/puerta_model.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../data/services/directions_service.dart';

class MapProvider with ChangeNotifier {
  final BanosRepository _banosRepository = BanosRepository();
  final PuertasRepository _puertasRepository = PuertasRepository();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  
  // Baños
  List<BanoModel> _banos = [];
  
  // Puertas 
  List<PuertaModel> _puertas = [];
  bool _showPuertas = true; // Toggle para mostrar/ocultar puertas
  
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filtros
  String? _selectedFacultad;
  String? _selectedPiso;
  String? _selectedGenero;
  bool _soloAccesibles = false;
  List<BanoModel> _banosFilteredList = [];
  int? _selectedBanoId;
  
  // Navegación
  bool _isNavigating = false;
  BanoModel? _destinationBano;
  List<LatLng> _routePoints = [];
  String? _routeDistance;
  String? _routeDuration;
  Set<Polyline> _polylines = {};
  final DirectionsService _directionsService = DirectionsService();

  // Estado de conectividad y cache
  bool _isOfflineMode = false;
  String? _offlineMessage;
  DateTime? _lastUpdate;

  // Callback para abrir detalle
  Function(int)? _onMarkerTapped;
  Function(int)? _onPuertaMarkerTapped; 

  // Coordenadas del centro de la Ciudadela Universitaria
  static const LatLng _ugCenter = LatLng(-2.18341, -79.8958);
  
  // Límites de la Ciudadela Universitaria (29.5 hectáreas)
  static final LatLngBounds _campusBounds = LatLngBounds(
    southwest: const LatLng(-2.1870, -79.8975),
    northeast: const LatLng(-2.1798, -79.8942),
  );

  // Getters existentes
  GoogleMapController? get mapController => _mapController;
  Position? get currentPosition => _currentPosition;
  List<BanoModel> get banos => _banos;
  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedFacultad => _selectedFacultad;
  String? get selectedPiso => _selectedPiso;
  String? get selectedGenero => _selectedGenero;
  bool get soloAccesibles => _soloAccesibles;
  
  
  List<BanoModel> get banosFiltered {
    // Si no hay ningún filtro activo, devolver todos los baños
    if (_selectedFacultad == null && 
        _selectedPiso == null && 
        _selectedGenero == null && 
        !_soloAccesibles) {
      return _banos;
    }
    // Si hay filtros activos, devolver lista filtrada (incluso si está vacía)
    return _banosFilteredList;
  }

  int? get selectedBanoId => _selectedBanoId;
  LatLng get initialPosition => _ugCenter;
  LatLngBounds get campusBounds => _campusBounds;
  bool get isNavigating => _isNavigating;
  BanoModel? get destinationBano => _destinationBano;
  String? get routeDistance => _routeDistance;
  String? get routeDuration => _routeDuration;
  Set<Polyline> get polylines => _polylines;
  bool get isOfflineMode => _isOfflineMode;
  String? get offlineMessage => _offlineMessage;
  DateTime? get lastUpdate => _lastUpdate;
  
  // Getters para puertas 
  List<PuertaModel> get puertas => _puertas;
  bool get showPuertas => _showPuertas;

  bool isInsideCampus(Position position) {
    return _campusBounds.contains(
      LatLng(position.latitude, position.longitude),
    );
  }

  void setOnMarkerTapped(Function(int) callback) {
    _onMarkerTapped = callback;
  }

  // NUEVO: Callback para cuando se toca una puerta
  void setOnPuertaMarkerTapped(Function(int) callback) {
    _onPuertaMarkerTapped = callback;
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Toggle para mostrar/ocultar puertas en el mapa
  void toggleShowPuertas() {
    _showPuertas = !_showPuertas;
    _createAllMarkers();
    notifyListeners();
  }

  /// Carga los baños Y puertas con soporte offline
  Future<void> loadBanos() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _offlineMessage = null;
      notifyListeners();

      if (_currentPosition == null) {
        await getCurrentLocation();
      }

      if (_currentPosition != null && !isInsideCampus(_currentPosition!)) {
        _errorMessage = 'Debes estar dentro de la Ciudadela Universitaria para usar esta aplicación.\n\nPor favor dirígete al campus para ver los baños disponibles.';
        _banos = [];
        _puertas = [];
        _markers = {};
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Cargar baños
      final banosResult = await _banosRepository.getBanos();
      _banos = banosResult.banos;
      
      // Cargar puertas 
      final puertasResult = await _puertasRepository.getPuertas();
      _puertas = puertasResult.puertas;
      
      // Determinar modo offline
      _isOfflineMode = banosResult.isFromCache || puertasResult.isFromCache;
      
      if (banosResult.message != null) {
        _offlineMessage = banosResult.message;
      } else if (puertasResult.message != null) {
        _offlineMessage = puertasResult.message;
      }
      
      _lastUpdate = DateTime.now();
      
      _createAllMarkers();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      
    } on NoCacheDataException catch (e) {
      _errorMessage = e.message;
      _banos = [];
      _puertas = [];
      _markers = {};
      _isLoading = false;
      _isOfflineMode = true;
      notifyListeners();
      
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fuerza actualización desde el servidor
  Future<bool> refreshFromServer() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final banosResult = await _banosRepository.forceRefresh();
      _banos = banosResult.banos;
      
      // También refrescar puertas
      final puertasResult = await _puertasRepository.getPuertas();
      _puertas = puertasResult.puertas;
      
      _isOfflineMode = false;
      _offlineMessage = banosResult.message;
      _lastUpdate = DateTime.now();
      
      _createAllMarkers();
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      
      if (_banos.isNotEmpty) {
        _offlineMessage = 'No se pudo actualizar. Usando datos guardados.';
      } else {
        _errorMessage = e.toString();
      }
      
      notifyListeners();
      return false;
    }
  }

  void clearOfflineMessage() {
    _offlineMessage = null;
    notifyListeners();
  }

  void _createAllMarkers() {
    _markers = {};
    

    // Esto asegura que si el filtro no tiene resultados, no se muestren baños
    for (var bano in banosFiltered) {
      _markers.add(
        Marker(
          markerId: MarkerId('bano_${bano.id}'),
          position: LatLng(bano.coordenadaLat, bano.coordenadaLng),
          infoWindow: InfoWindow(
            title: bano.nombre,
            snippet: '${bano.piso} - ${bano.estado}',
          ),
          icon: _getMarkerIcon(bano.estado),
          onTap: () {
            _onMarkerTapped?.call(bano.id);
          },
        ),
      );
    }
    
    // Agregar marcadores de puertas (si están habilitadas)
    if (_showPuertas) {
      for (var puerta in _puertas) {
        _markers.add(
          Marker(
            markerId: MarkerId('puerta_${puerta.id}'),
            position: LatLng(puerta.coordenadaLat, puerta.coordenadaLng),
            infoWindow: InfoWindow(
              title: '🚪 ${puerta.nombre}',
              snippet: puerta.isOpen ? '✅ Abierta' : '🔴 Cerrada',
            ),
            icon: _getPuertaMarkerIcon(puerta.estado),
            onTap: () {
              _onPuertaMarkerTapped?.call(puerta.id);
            },
          ),
        );
      }
    }
  }

  BitmapDescriptor _getMarkerIcon(String estado) {
    switch (estado) {
      case 'disponible':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'mantenimiento':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);  
      case 'cerrado':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);    
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  /// Icono para marcadores de puertas
  BitmapDescriptor _getPuertaMarkerIcon(String estado) {
    // Azul para puerta abierta, Violeta para cerrada
    if (estado == 'abierta') {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Los servicios de ubicación están deshabilitados. Por favor actívalos en Configuración.';
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          _errorMessage = 'Permisos de ubicación denegados';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Permisos de ubicación denegados permanentemente. Ve a Configuración de la app para habilitarlos.';
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('📍 Ubicación obtenida: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error al obtener ubicación: $e');
      _errorMessage = 'Error al obtener ubicación: $e';
      notifyListeners();
    }
  }

  /// Obtiene una puerta por ID
  PuertaModel? getPuertaById(int id) {
    try {
      return _puertas.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Encuentra la puerta más cercana a una posición
  PuertaModel? findNearestPuerta(double lat, double lng) {
    if (_puertas.isEmpty) return null;

    PuertaModel? nearest;
    double minDistance = double.infinity;

    for (var puerta in _puertas) {
      // Solo considerar puertas abiertas
      if (!puerta.isOpen) continue;

      final distance = DistanceCalculator.calculateDistance(
        lat, lng,
        puerta.coordenadaLat, puerta.coordenadaLng,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = puerta;
      }
    }

    return nearest;
  }

  /// Encuentra la puerta más cercana a un baño específico
  PuertaModel? findNearestPuertaToBano(BanoModel bano) {
    return findNearestPuerta(bano.coordenadaLat, bano.coordenadaLng);
  }

  /// Calcula la distancia entre una puerta y un baño
  double? getDistancePuertaToBano(PuertaModel puerta, BanoModel bano) {
    return DistanceCalculator.calculateDistance(
      puerta.coordenadaLat, puerta.coordenadaLng,
      bano.coordenadaLat, bano.coordenadaLng,
    );
  }

  void setFacultadFilter(String? facultad) {
    _selectedFacultad = facultad;
    _applyFilters();
  }

  void setPisoFilter(String? piso) {
    _selectedPiso = piso;
    _applyFilters();
  }

  void setGeneroFilter(String? genero) {
    _selectedGenero = genero;
    _applyFilters();
  }

  void setAccesibilidadFilter(bool value) {
    _soloAccesibles = value;
    _applyFilters();
  }

  void clearFilters() {
    _selectedFacultad = null;
    _selectedPiso = null;
    _selectedGenero = null;
    _soloAccesibles = false;
    _banosFilteredList = [];
    _createAllMarkers();
    notifyListeners();
  }

  void _applyFilters() {
    _banosFilteredList = _banos.where((bano) {
      if (_selectedFacultad != null && bano.facultadNombre != _selectedFacultad) {
        return false;
      }
      if (_selectedPiso != null && bano.piso != _selectedPiso) {
        return false;
      }
      if (_selectedGenero != null && bano.genero != _selectedGenero) {
        return false;
      }
      if (_soloAccesibles && !bano.accesibilidad) {
        return false;
      }
      return true;
    }).toList();

    _createAllMarkers();
    notifyListeners();
  }

  BanoModel? getBanoById(int id) {
    try {
      return _banos.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  BanoModel? findNearestBano(Position position) {
    if (_banos.isEmpty) return null;

    BanoModel? nearest;
    double minDistance = double.infinity;

    // el botón "Ir al baño más cercano" respete los filtros
    for (var bano in banosFiltered) {
      if (bano.estado != 'disponible') continue;

      final distance = DistanceCalculator.calculateDistance(
        position.latitude,
        position.longitude,
        bano.coordenadaLat,
        bano.coordenadaLng,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = bano;
      }
    }

    return nearest;
  }

  Future<bool> startNavigation(BanoModel bano) async {
    if (_currentPosition == null) {
      _errorMessage = 'No se pudo obtener tu ubicación';
      notifyListeners();
      return false;
    }

    if (_isOfflineMode) {
      _errorMessage = 'La navegación requiere conexión a internet para calcular la ruta.';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final destination = LatLng(bano.coordenadaLat, bano.coordenadaLng);

      final directions = await _directionsService.getDirections(origin, destination);

      if (directions != null) {
        _routePoints = _directionsService.decodePolyline(directions['polyline']);
        _routeDistance = directions['distance'];
        _routeDuration = directions['duration'];
        _destinationBano = bano;
        _isNavigating = true;

        _createRoutePolyline();

        if (_mapController != null) {
          try {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(
                _getRouteBounds(),
                50,
              ),
            );
          } catch (e) {
            print('⚠️ Error al animar cámara: $e');
          }
        }

        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'No se pudo calcular la ruta. Verifica tu conexión a internet.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al calcular ruta: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _createRoutePolyline() {
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: const Color(0xFF2196F3),
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  LatLngBounds _getRouteBounds() {
    double minLat = _routePoints[0].latitude;
    double maxLat = _routePoints[0].latitude;
    double minLng = _routePoints[0].longitude;
    double maxLng = _routePoints[0].longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void stopNavigation() {
    _isNavigating = false;
    _destinationBano = null;
    _routePoints = [];
    _routeDistance = null;
    _routeDuration = null;
    _polylines = {};
    notifyListeners();
  }

  Future<void> updateLocationDuringNavigation() async {
    if (!_isNavigating || _currentPosition == null || _destinationBano == null) {
      return;
    }

    await getCurrentLocation();

    final distance = DistanceCalculator.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destinationBano!.coordenadaLat,
      _destinationBano!.coordenadaLng,
    );

    if (distance < 20) {
      stopNavigation();
      _errorMessage = '¡Has llegado a tu destino!';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }
}