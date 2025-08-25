import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import 'mapeo_screen.dart';

class ParametrosScreen extends StatefulWidget {
  const ParametrosScreen({super.key});

  @override
  State<ParametrosScreen> createState() => _ParametrosScreenState();
}

class _ParametrosScreenState extends State<ParametrosScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MainScaffold(
      title: 'Administración de Parámetros',
      onRefresh: () async {
        await authProvider.checkAuthStatus();
      },
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildCategoriesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parámetros del Sistema',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona una categoría para gestionar sus parámetros',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = _getCategories();
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (category['color'] as Color).withOpacity(0.1),
              (category['color'] as Color).withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: (category['color'] as Color).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _showCategoryDetails(category),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: category['color'] as Color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${category['subcategories'].length} subcategorías',
                  style: TextStyle(
                    fontSize: 12,
                    color: (category['color'] as Color).withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryDetails(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              category['icon'] as IconData,
              color: category['color'] as Color,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(category['name']),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: (category['subcategories'] as List).length,
            itemBuilder: (context, index) {
              final subcategory = (category['subcategories'] as List)[index];
              return _buildSubcategoryCard(subcategory, category['color'] as Color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory, Color categoryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: categoryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _showSubcategoryDetails(subcategory, categoryColor);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  subcategory['icon'] as IconData,
                  color: categoryColor,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  subcategory['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubcategoryDetails(Map<String, dynamic> subcategory, Color categoryColor) {
    // Si es la subcategoría de Mapeo, navegar directamente a la pantalla de mapeo
    if (subcategory['name'] == 'Configuración de Mapas' || subcategory['name'] == 'Capas de Información') {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapeoScreen()),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              subcategory['icon'] as IconData,
              color: categoryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(subcategory['name']),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descripción:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subcategory['description']),
            const SizedBox(height: 16),
            Text(
              'Parámetros disponibles:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(subcategory['parameters'] as List).map((param) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 16, color: categoryColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(param)),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Accediendo a ${subcategory['name']}'),
                  backgroundColor: categoryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: categoryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Acceder'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCategories() {
    return [
      {
        'name': 'General',
        'color': AppTheme.primaryColor,
        'icon': Icons.settings,
        'subcategories': [
          {
            'name': 'Información Empresarial',
            'description': 'Datos básicos de la empresa',
            'icon': Icons.business,
            'parameters': ['Nombre de la Empresa', 'CUIT', 'Dirección', 'Teléfono', 'Email'],
          },
          {
            'name': 'Configuración Sistema',
            'description': 'Ajustes del sistema',
            'icon': Icons.tune,
            'parameters': ['Idioma', 'Zona Horaria', 'Moneda', 'Unidad de Medida'],
          },
          {
            'name': 'Responsables',
            'description': 'Personal responsable',
            'icon': Icons.people,
            'parameters': ['Responsable Técnico', 'Encargado de Producción'],
          },
        ],
      },
      {
        'name': 'Mapeo',
        'color': AppTheme.accentColor,
        'icon': Icons.map,
        'subcategories': [
          {
            'name': 'Configuración de Mapas',
            'description': 'Ajustes de visualización',
            'icon': Icons.map_outlined,
            'parameters': ['Escala del Mapa', 'Zoom Mínimo', 'Zoom Máximo'],
          },
          {
            'name': 'Capas de Información',
            'description': 'Capas disponibles en mapas',
            'icon': Icons.layers,
            'parameters': ['Capas de Cultivos', 'Capas de Riego', 'Capas de Suelo'],
          },
        ],
      },
      {
        'name': 'Riegos',
        'color': AppTheme.infoColor,
        'icon': Icons.water_drop,
        'subcategories': [
          {
            'name': 'Configuración de Riego',
            'description': 'Parámetros de riego automático',
            'icon': Icons.water,
            'parameters': ['Frecuencia de Riego', 'Presión Mínima', 'Duración Máxima'],
          },
          {
            'name': 'Zonas de Riego',
            'description': 'Gestión de zonas de riego',
            'icon': Icons.location_on,
            'parameters': ['Zonas Activas', 'Horarios de Riego', 'Consumo de Agua'],
          },
        ],
      },
      {
        'name': 'Cecos',
        'color': AppTheme.successColor,
        'icon': Icons.account_balance,
        'subcategories': [
          {
            'name': 'Centros de Costo',
            'description': 'Gestión de centros de costo',
            'icon': Icons.account_balance_wallet,
            'parameters': ['Ceco Principal', 'Ceco Producción', 'Ceco Mantenimiento'],
          },
          {
            'name': 'Asignación de Costos',
            'description': 'Distribución de costos',
            'icon': Icons.attach_money,
            'parameters': ['Distribución por Hectárea', 'Costos por Cultivo'],
          },
        ],
      },
      {
        'name': 'Cuarteles',
        'color': AppTheme.warningColor,
        'icon': Icons.grid_on,
        'subcategories': [
          {
            'name': 'Configuración de Cuarteles',
            'description': 'Parámetros de diseño de cuarteles',
            'icon': Icons.grid_4x4,
            'parameters': ['Distancia entre Hileras', 'Distancia entre Plantas', 'Plantas por Hectárea'],
          },
          {
            'name': 'Gestión de Hileras',
            'description': 'Configuración de hileras',
            'icon': Icons.view_column,
            'parameters': ['Ancho de Hileras', 'Espaciado', 'Orientación'],
          },
        ],
      },
    ];
  }
}
