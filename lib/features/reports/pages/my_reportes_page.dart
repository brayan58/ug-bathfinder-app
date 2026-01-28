import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reportes_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class MyReportesPage extends StatefulWidget {
  const MyReportesPage({super.key});

  @override
  State<MyReportesPage> createState() => _MyReportesPageState();
}

class _MyReportesPageState extends State<MyReportesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportesProvider>().loadMyReportes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportesProvider = context.watch<ReportesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => reportesProvider.loadMyReportes(),
          ),
        ],
      ),
      body: reportesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportesProvider.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(reportesProvider.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => reportesProvider.loadMyReportes(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : reportesProvider.reportes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.report_off,
                              size: 64, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text(
                            'No has realizado reportes',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => reportesProvider.loadMyReportes(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reportesProvider.reportes.length,
                        itemBuilder: (context, index) {
                          final reporte = reportesProvider.reportes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header con nombre y estado
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: reporte.isReportePuerta
                                              ? Colors.blue.shade100
                                              : AppColors.primary
                                                  .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          reporte.isReportePuerta
                                              ? Icons.door_front_door
                                              : Icons.wc,
                                          size: 20,
                                          color: reporte.isReportePuerta
                                              ? Colors.blue.shade700
                                              : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reporte.nombreRecurso,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              reporte.codigoRecurso,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildEstadoChip(reporte.estado),
                                    ],
                                  ),

                                  // Badge de tipo de recurso 
                                  if (reporte.isReportePuerta) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '🚪 Reporte de puerta',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const Divider(height: 24),

                                  _buildInfoRow(
                                    Icons.report_problem,
                                    'Tipo',
                                    _formatTipo(reporte.tipo),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.priority_high,
                                    'Urgencia',
                                    _formatUrgencia(reporte.urgencia),
                                    color: _getUrgenciaColor(reporte.urgencia),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.calendar_today,
                                    'Fecha',
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(reporte.fechaCreacion),
                                  ),

                                  // Facultad (solo para baños)
                                  if (reporte.isReporteBano &&
                                      reporte.facultadNombre != null) ...[
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      Icons.school,
                                      'Facultad',
                                      reporte.facultadNombre!,
                                    ),
                                  ],

                                  if (reporte.descripcion != null) ...[
                                    const Divider(height: 24),
                                    const Text(
                                      'Descripción:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(reporte.descripcion!),
                                  ],
                                  if (reporte.notaAdmin != null) ...[
                                    const Divider(height: 24),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Respuesta del administrador:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(reporte.notaAdmin!),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String label;

    switch (estado) {
      case 'pendiente':
        color = AppColors.cerrado;
        label = 'Pendiente';
        break;
      case 'en_proceso':
        color = Colors.orange;
        label = 'En proceso';
        break;
      case 'resuelto':
        color = AppColors.disponible;
        label = 'Resuelto';
        break;
      case 'rechazado':
        color = AppColors.mantenimiento;
        label = 'Rechazado';
        break;
      default:
        color = AppColors.textSecondary;
        label = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTipo(String tipo) {
    final Map<String, String> tipos = {
      'limpieza': '🧹 Limpieza',
      'dano_instalaciones': '🔧 Daño en instalaciones',
      'sin_papel': '🧻 Sin papel',
      'sin_agua': '💧 Sin agua',
      'puerta_danada': '🚪 Puerta dañada',
      'sin_luz': '💡 Sin luz',
      'otro': '📝 Otro',
      'puerta_cerrada': '🚪 Puerta cerrada',
    };
    return tipos[tipo] ?? tipo;
  }

  //  Ahora acepta String? para urgencia
  String _formatUrgencia(String? urgencia) {
    if (urgencia == null || urgencia.isEmpty) {
      return 'Sin asignar';
    }

    final Map<String, String> urgencias = {
      'baja': 'Baja',
      'media': 'Media',
      'alta': 'Alta',
    };
    return urgencias[urgencia] ?? urgencia;
  }

  Color _getUrgenciaColor(String? urgencia) {
    if (urgencia == null || urgencia.isEmpty) {
      return AppColors.textSecondary;
    }

    switch (urgencia) {
      case 'baja':
        return AppColors.disponible;
      case 'media':
        return Colors.orange;
      case 'alta':
        return AppColors.mantenimiento;
      default:
        return AppColors.textSecondary;
    }
  }
}
