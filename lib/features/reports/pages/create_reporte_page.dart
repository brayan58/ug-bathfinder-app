import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reportes_provider.dart';
import '../../../data/models/bano_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';


class CreateReportePage extends StatefulWidget {
  final BanoModel bano;

  const CreateReportePage({super.key, required this.bano});

  @override
  State<CreateReportePage> createState() => _CreateReportePageState();
}

class _CreateReportePageState extends State<CreateReportePage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();

  String? _selectedTipo;
  String _selectedUrgencia = 'media';

  final Map<String, String> _tipos = {
    'limpieza': AppStrings.tipoLimpieza,
    'dano_instalaciones': AppStrings.tipoDanoInstalaciones,
    'sin_papel': AppStrings.tipoSinPapel,
    'sin_agua': AppStrings.tipoSinAgua,
    'puerta_danada': AppStrings.tipoPuertaDanada,
    'sin_luz': AppStrings.tipoSinLuz,
    'otro': AppStrings.tipoOtro,
  };

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Problema'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card del baño seleccionado
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Baño seleccionado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.bano.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.bano.codigo,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Tipo de problema
              const Text(
                'Tipo de problema *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedTipo,
                decoration: const InputDecoration(
                  hintText: 'Selecciona el tipo',
                  prefixIcon: Icon(Icons.report_problem),
                ),
                items: _tipos.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTipo = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Debes seleccionar un tipo de problema';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Urgencia
              const Text(
                'Urgencia *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'baja',
                    label: Text('Baja'),
                    icon: Icon(Icons.info_outline),
                  ),
                  ButtonSegment(
                    value: 'media',
                    label: Text('Media'),
                    icon: Icon(Icons.warning_amber),
                  ),
                  ButtonSegment(
                    value: 'alta',
                    label: Text('Alta'),
                    icon: Icon(Icons.error_outline),
                  ),
                ],
                selected: {_selectedUrgencia},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedUrgencia = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Descripción
              const Text(
                'Descripción (opcional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe el problema con más detalle...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              
              // Botón de enviar
              Consumer<ReportesProvider>(
                builder: (context, reportesProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: reportesProvider.isLoading
                          ? null
                          : () => _handleSubmit(reportesProvider),
                      child: reportesProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('ENVIAR REPORTE'),
                    ),
                  );
                },
              ),
              
              // Nota sobre conexión
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Se requiere conexión a internet para enviar el reporte.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(ReportesProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await provider.createReporte(
      banoId: widget.bano.id,
      tipo: _selectedTipo!,
      urgencia: _selectedUrgencia,
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reporte enviado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      // Mostrar diálogo de error más visible si es error de conexión
      if (provider.isConnectionError) {
        _showConnectionErrorDialog(provider.errorMessage ?? 'Error de conexión');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al enviar reporte'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Muestra un diálogo cuando hay error de conexión
  void _showConnectionErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.wifi_off, color: Colors.orange, size: 48),
        title: const Text('Sin conexión'),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('REINTENTAR'),
            onPressed: () {
              Navigator.pop(context);
              _handleSubmit(context.read<ReportesProvider>());
            },
          ),
        ],
      ),
    );
  }
}