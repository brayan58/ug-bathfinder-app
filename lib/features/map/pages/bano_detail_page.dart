import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../../../data/models/bano_model.dart';
import '../../../data/models/puerta_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../reports/pages/create_reporte_page.dart';

class BanoDetailPage extends StatelessWidget {
  final int banoId;

  const BanoDetailPage({super.key, required this.banoId});

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final bano = mapProvider.getBanoById(banoId);

    if (bano == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Baño no encontrado')),
        body: const Center(child: Text('Baño no encontrado')),
      );
    }

    // Encontrar la puerta más cercana
    final puertaCercana = mapProvider.findNearestPuertaToBano(bano);
    double? distanciaPuerta;
    if (puertaCercana != null) {
      distanciaPuerta =
          mapProvider.getDistancePuertaToBano(puertaCercana, bano);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(bano.nombre),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(bano),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(bano, mapProvider),
                  const SizedBox(height: 16),
                  _buildDetailsCard(bano),
                  const SizedBox(height: 16),

                  // Sección de entrada sugerida
                  if (puertaCercana != null)
                    _buildEntradaSugeridaCard(puertaCercana, distanciaPuerta),

                  if (puertaCercana != null) const SizedBox(height: 16),

                  _buildActionButtons(context, bano, mapProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BanoModel bano) {
    Color color;
    String text;
    IconData icon;

    switch (bano.estado) {
      case 'disponible':
        color = AppColors.disponible;
        text = 'DISPONIBLE';
        icon = Icons.check_circle;
        break;
      case 'mantenimiento':
        color = AppColors.mantenimiento;
        text = 'EN MANTENIMIENTO';
        icon = Icons.build;
        break;
      case 'cerrado':
        color = AppColors.cerrado;
        text = 'CERRADO';
        icon = Icons.block;
        break;
      default:
        color = AppColors.cerrado;
        text = 'DESCONOCIDO';
        icon = Icons.help;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BanoModel bano, MapProvider mapProvider) {
    String? distance;
    if (mapProvider.currentPosition != null) {
      final dist = DistanceCalculator.calculateDistance(
        mapProvider.currentPosition!.latitude,
        mapProvider.currentPosition!.longitude,
        bano.coordenadaLat,
        bano.coordenadaLng,
      );
      distance = DistanceCalculator.formatDistance(dist);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bano.nombre,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Código: ${bano.codigo}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (distance != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(distance),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BanoModel bano) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.school, 'Facultad', bano.facultadNombre ?? 'N/A'),
            _detailRow(Icons.layers, 'Piso', bano.piso),
            _detailRow(Icons.wc, 'Género', _formatGenero(bano.genero)),
            _detailRow(
              Icons.accessible,
              'Accesibilidad',
              bano.accesibilidad ? 'Sí' : 'No',
              color: bano.accesibilidad ? AppColors.success : null,
            ),
          ],
        ),
      ),
    );
  }

  // Card de entrada sugerida
  Widget _buildEntradaSugeridaCard(PuertaModel puerta, double? distancia) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.door_front_door, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Entrada sugerida',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nombre de la puerta
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: puerta.isOpen
                        ? AppColors.disponible
                        : AppColors.mantenimiento,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    puerta.codigo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    puerta.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Estado de la puerta
            Row(
              children: [
                Icon(
                  puerta.isOpen ? Icons.lock_open : Icons.lock,
                  size: 16,
                  color: puerta.isOpen
                      ? AppColors.disponible
                      : AppColors.mantenimiento,
                ),
                const SizedBox(width: 4),
                Text(
                  puerta.isOpen ? 'Abierta' : 'Cerrada',
                  style: TextStyle(
                    color: puerta.isOpen
                        ? AppColors.disponible
                        : AppColors.mantenimiento,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Distancia aproximada
                if (distancia != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.straighten,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~${DistanceCalculator.formatDistance(distancia)} hasta el baño',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),

            // Descripción de la puerta si existe
            if (puerta.descripcion != null &&
                puerta.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                puerta.descripcion!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Horario si está definido
            if (puerta.horarioApertura != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Horario: ${puerta.horarioFormatted}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],

            // Advertencia si la puerta está cerrada
            if (!puerta.isOpen) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        size: 18, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta puerta está cerrada. Busca otra entrada.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, BanoModel bano, MapProvider mapProvider) {
    return Column(
      children: [
        if (bano.estado == 'disponible')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions),
              label: const Text('INICIAR NAVEGACIÓN'),
              onPressed: () async {
                final success = await mapProvider.startNavigation(bano);

                if (!context.mounted) return;

                if (success) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navegación iniciada'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(mapProvider.errorMessage ??
                          'Error al iniciar navegación'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ),
        if (bano.estado == 'disponible') const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.report),
            label: const Text('REPORTAR PROBLEMA'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateReportePage(bano: bano),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatGenero(String genero) {
    switch (genero) {
      case 'hombres':
        return 'Hombres';
      case 'mujeres':
        return 'Mujeres';
      case 'universal':
        return 'Universal';
      default:
        return genero;
    }
  }
}
