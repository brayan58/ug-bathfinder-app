import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/map_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'bano_detail_page.dart';
import '../../reports/pages/my_reportes_page.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/puerta_model.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = context.read<MapProvider>();
      mapProvider.loadBanos();

      // Callback para baños
      mapProvider.setOnMarkerTapped((banoId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BanoDetailPage(banoId: banoId),
          ),
        );
      });

      // Callback para puertas (NUEVO)
      mapProvider.setOnPuertaMarkerTapped((puertaId) {
        _showPuertaBottomSheet(context, puertaId);
      });
    });
  }

  /// Muestra un bottom sheet con información de la puerta
  void _showPuertaBottomSheet(BuildContext context, int puertaId) {
    final mapProvider = context.read<MapProvider>();
    final puerta = mapProvider.getPuertaById(puertaId);

    if (puerta == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PuertaBottomSheet(puerta: puerta),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mapProvider = context.watch<MapProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Baños'),
        actions: [
          // Botón de filtros
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const FilterBottomSheet(),
              );
            },
          ),

          // Botón de "Mis Reportes"
          IconButton(
            icon: const Icon(Icons.assignment),
            tooltip: 'Mis Reportes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyReportesPage(),
                ),
              );
            },
          ),

          // Botón de refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final success = await mapProvider.refreshFromServer();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '✅ Datos actualizados correctamente'
                          : '⚠️ No se pudo actualizar. Usando datos guardados.',
                    ),
                    backgroundColor:
                        success ? AppColors.success : Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),

          // Botón de logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: mapProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : mapProvider.errorMessage != null
              ? _buildErrorView(mapProvider)
              : Stack(
                  children: [
                    // Mapa principal
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: mapProvider.initialPosition,
                        zoom: 17,
                      ),
                      markers: mapProvider.markers,
                      polylines: mapProvider.polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      cameraTargetBounds: CameraTargetBounds(
                        mapProvider.campusBounds,
                      ),
                      minMaxZoomPreference: const MinMaxZoomPreference(15, 20),
                      onMapCreated: (controller) {
                        mapProvider.setMapController(controller);
                      },
                    ),

                    // Banner de modo offline
                    if (mapProvider.isOfflineMode &&
                        mapProvider.offlineMessage != null)
                      _buildOfflineBanner(mapProvider),

                    // Panel de navegación
                    if (mapProvider.isNavigating)
                      _buildNavigationPanel(mapProvider),

                    // Card de información
                    if (!mapProvider.isNavigating)
                      Positioned(
                        top: mapProvider.isOfflineMode ? 60 : 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Baños: ${mapProvider.banosFiltered.length} | Puertas: ${mapProvider.puertas.length}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Toggle para puertas (NUEVO)
                                TextButton.icon(
                                  icon: Icon(
                                    mapProvider.showPuertas
                                        ? Icons.door_front_door
                                        : Icons.door_front_door_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    mapProvider.showPuertas
                                        ? 'Ocultar'
                                        : 'Mostrar',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () =>
                                      mapProvider.toggleShowPuertas(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Botones flotantes
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Column(
                        children: [
                          if (!mapProvider.isNavigating) ...[
                            FloatingActionButton(
                              heroTag: 'location',
                              child: const Icon(Icons.my_location),
                              onPressed: () => mapProvider.getCurrentLocation(),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              heroTag: 'nearest',
                              child: const Icon(Icons.near_me),
                              onPressed: () =>
                                  _findNearestBano(context, mapProvider),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              heroTag: 'legend',
                              child: const Icon(Icons.info),
                              onPressed: () => _showLegend(context),
                            ),
                          ] else ...[
                            FloatingActionButton(
                              heroTag: 'stop',
                              backgroundColor: AppColors.error,
                              child: const Icon(Icons.close),
                              onPressed: () => mapProvider.stopNavigation(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOfflineBanner(MapProvider mapProvider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade400, width: 2),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Modo sin conexión',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        mapProvider.offlineMessage ?? 'Usando datos guardados',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.refresh,
                      size: 18, color: Colors.orange.shade800),
                  label: Text(
                    'Reintentar',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                  onPressed: () async {
                    final success = await mapProvider.refreshFromServer();
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Conexión restaurada'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(MapProvider mapProvider) {
    final isConnectionError =
        mapProvider.errorMessage?.contains('conexión') ?? false;
    final isLocationError =
        mapProvider.errorMessage?.contains('ubicación') ?? false;
    final isCampusError = mapProvider.errorMessage?.contains('campus') ??
        mapProvider.errorMessage?.contains('Ciudadela') ??
        false;

    IconData errorIcon;
    Color errorColor;

    if (isConnectionError) {
      errorIcon = Icons.wifi_off;
      errorColor = Colors.orange;
    } else if (isLocationError) {
      errorIcon = Icons.location_off;
      errorColor = AppColors.error;
    } else if (isCampusError) {
      errorIcon = Icons.location_off;
      errorColor = AppColors.error;
    } else {
      errorIcon = Icons.error_outline;
      errorColor = AppColors.error;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(errorIcon, size: 80, color: errorColor),
            const SizedBox(height: 24),
            Text(
              mapProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
              onPressed: () => mapProvider.loadBanos(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationPanel(MapProvider mapProvider) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.navigation, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mapProvider.destinationBano?.nombre ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.straighten,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(mapProvider.routeDistance ?? ''),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(mapProvider.routeDuration ?? ''),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _findNearestBano(BuildContext context, MapProvider mapProvider) {
    if (mapProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obteniendo tu ubicación...'),
          duration: Duration(seconds: 2),
        ),
      );

      mapProvider.getCurrentLocation().then((_) {
        if (mapProvider.currentPosition != null) {
          final nearest =
              mapProvider.findNearestBano(mapProvider.currentPosition!);

          if (nearest != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BanoDetailPage(banoId: nearest.id),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hay baños disponibles cerca')),
            );
          }
        }
      });

      return;
    }

    final nearest = mapProvider.findNearestBano(mapProvider.currentPosition!);

    if (nearest != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BanoDetailPage(banoId: nearest.id),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay baños disponibles cerca')),
      );
    }
  }

  void _showLegend(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leyenda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Baños:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _legendItem(AppColors.disponible, 'Disponible'),
            _legendItem(AppColors.mantenimiento, 'Mantenimiento'),
            _legendItem(AppColors.cerrado, 'Cerrado'),
            const Divider(height: 24),
            const Text(
              'Puertas:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _legendItem(Colors.blue, 'Puerta abierta'),
            _legendItem(Colors.purple, 'Puerta cerrada'),
            const Divider(height: 24),
            _legendItem(Colors.orange, 'Modo offline'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

/// Bottom sheet para mostrar información de una puerta
class _PuertaBottomSheet extends StatelessWidget {
  final PuertaModel puerta;

  const _PuertaBottomSheet({required this.puerta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: puerta.isOpen
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.door_front_door,
                  color: puerta.isOpen ? Colors.green : Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puerta.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Código: ${puerta.codigo}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: puerta.isOpen ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: puerta.isOpen ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  puerta.isOpen ? Icons.lock_open : Icons.lock,
                  color: puerta.isOpen ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  puerta.isOpen ? 'ABIERTA' : 'CERRADA',
                  style: TextStyle(
                    color: puerta.isOpen
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Descripción
          if (puerta.descripcion != null && puerta.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              puerta.descripcion!,
              style: const TextStyle(fontSize: 14),
            ),
          ],

          // Horario
          if (puerta.horarioApertura != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Horario: ${puerta.horarioFormatted}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],

          // Es principal
          if (puerta.esPrincipal) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Entrada principal',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Botón de reportar (si está cerrada)
          if (!puerta.isOpen)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.report),
                label: const Text('REPORTAR PUERTA CERRADA'),
                onPressed: () {
                  Navigator.pop(context);
                 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de reporte próximamente'),
                    ),
                  );
                },
              ),
            ),

          // Botón de cerrar
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CERRAR'),
            ),
          ),
        ],
      ),
    );
  }
}
