import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../core/config/env_config.dart';

class DirectionsService {
  final Dio _dio = Dio();

  
  static const String _apiKey = EnvConfig.googleMapsApiKey;


  Future<Map<String, dynamic>?> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      print('🗺️ Solicitando ruta de $origin a $destination');

      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=walking'
          '&key=$_apiKey';

      print('📍 URL completa: $url');

      final response = await _dio.get(url);

      print('✅ Response status code: ${response.statusCode}');
      print('📄 Response status: ${response.data['status']}');
      print('📄 Response completo: ${response.data}');

      if (response.data['status'] == 'OK') {
        final route = response.data['routes'][0];
        final polylinePoints = route['overview_polyline']['points'];

        return {
          'polyline': polylinePoints,
          'distance': route['legs'][0]['distance']['text'],
          'duration': route['legs'][0]['duration']['text'],
          'steps': route['legs'][0]['steps'],
        };
      } else {
        print('❌ Status NO OK: ${response.data['status']}');
        print('❌ Error message: ${response.data['error_message']}');
        return null;
      }
    } catch (e) {
      print('❌ ERROR COMPLETO: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
      if (e is DioException) {
        print('❌ DioException response: ${e.response?.data}');
        print('❌ DioException message: ${e.message}');
      }
      return null;
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encoded);

    return result
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }
}
