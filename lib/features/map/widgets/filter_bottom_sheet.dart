import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../../../core/constants/app_colors.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    
    final facultades = mapProvider.banos
        .map((b) => b.facultadNombre)
        .where((f) => f != null)
        .toSet()
        .toList();
    
    final pisos = ['PB', 'P1', 'P2', 'P3', 'P4'];
    final generos = ['hombres', 'mujeres', 'universal'];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  mapProvider.clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: mapProvider.selectedFacultad,
            decoration: const InputDecoration(
              labelText: 'Facultad',
              prefixIcon: Icon(Icons.school),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              ...facultades.map((f) => DropdownMenuItem(value: f, child: Text(f!))),
            ],
            onChanged: (value) => mapProvider.setFacultadFilter(value),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: mapProvider.selectedPiso,
            decoration: const InputDecoration(
              labelText: 'Piso',
              prefixIcon: Icon(Icons.layers),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...pisos.map((p) => DropdownMenuItem(value: p, child: Text(p))),
            ],
            onChanged: (value) => mapProvider.setPisoFilter(value),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: mapProvider.selectedGenero,
            decoration: const InputDecoration(
              labelText: 'Género',
              prefixIcon: Icon(Icons.wc),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...generos.map((g) => DropdownMenuItem(value: g, child: Text(_formatGenero(g)))),
            ],
            onChanged: (value) => mapProvider.setGeneroFilter(value),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Solo accesibles'),
            subtitle: const Text('Baños con rampas/elevador'),
            value: mapProvider.soloAccesibles,
            onChanged: (value) => mapProvider.setAccesibilidadFilter(value),
            activeThumbColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('APLICAR FILTROS'),
            ),
          ),
        ],
      ),
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