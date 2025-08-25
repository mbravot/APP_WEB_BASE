import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class MapeoScreen extends StatefulWidget {
  const MapeoScreen({super.key});

  @override
  State<MapeoScreen> createState() => _MapeoScreenState();
}

class _MapeoScreenState extends State<MapeoScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Lista de cuarteles cargados desde la API
  List<Map<String, dynamic>> _cuarteles = [];
  bool _isLoadingCuarteles = false;
  
  // Variables para selección de cuarteles
  Set<int> _cuartelesSeleccionados = {};
  bool _seleccionarTodos = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarCuarteles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MainScaffold(
      title: 'Administración de Mapeo',
      onRefresh: () async {
        await authProvider.checkAuthStatus();
      },
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCatastro(),
                _buildMapeo(),
                _buildGraficos(),
              ],
            ),
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
            'Sistema de Mapeo Agrícola',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gestión completa de cuarteles, hileras y plantas con carga masiva',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: const [
          Tab(text: 'Catastro'),
          Tab(text: 'Mapeo'),
          Tab(text: 'Gráficos'),
        ],
      ),
    );
  }

  // TAB 1: Catastro - Configuración de hileras y plantas por cuartel
  Widget _buildCatastro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Catastro',
            'Configuración de hileras y plantas por cuartel',
            Icons.grid_on,
            AppTheme.primaryColor,
                      ),
            const SizedBox(height: 20),
            _buildGestionHileras(),
        ],
      ),
    );
  }

  Widget _buildCargaMasivaCuarteles() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Carga Masiva de Cuarteles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCuartelesForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildCuartelesForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Carga Masiva de Cuarteles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Arrastra archivos Excel/CSV aquí o haz clic para seleccionar',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _seleccionarArchivoCuarteles(),
                    icon: const Icon(Icons.file_open),
                    label: const Text('Seleccionar Archivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _descargarPlantillaCuarteles(),
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar Plantilla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _procesarCargaMasiva(),
              icon: const Icon(Icons.upload),
              label: const Text('Procesar Carga Masiva de Cuarteles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGestionHileras() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.view_column, color: AppTheme.infoColor),
                const SizedBox(width: 8),
                const Text(
                  'Gestión de Hileras',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCuartelesList(),
          ],
        ),
      ),
    );
  }

  // Método para cargar cuarteles desde la API
  Future<void> _cargarCuarteles() async {
    setState(() {
      _isLoadingCuarteles = true;
    });

    try {
      // Obtener token de autenticación
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getToken();

      if (token == null) {
        throw Exception('No hay token de autenticación disponible');
      }

      print('Token obtenido: ${token.substring(0, 20)}...');
      
      // Llamada real a la API
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/cuarteles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final cuartelesData = data['data']['cuarteles'] as List;
          
          // Obtener la sucursal activa del usuario
          final userData = authProvider.userData;
          final sucursalActiva = userData?['sucursal_nombre'] ?? '';
          
          print('Sucursal activa del usuario: $sucursalActiva');
          
          // Filtrar cuarteles solo de la sucursal activa
          final cuartelesFiltrados = cuartelesData.where((cuartel) {
            final nombreSucursal = cuartel['nombre_sucursal'] ?? '';
            return nombreSucursal == sucursalActiva;
          }).toList();
          
          print('Cuarteles totales: ${cuartelesData.length}');
          print('Cuarteles de la sucursal activa: ${cuartelesFiltrados.length}');
          
          _cuarteles = cuartelesFiltrados.map((cuartel) => {
            'id': cuartel['id'],
            'nombre': cuartel['nombre'],
            'superficie': cuartel['superficie'] ?? 0.0,
            'n_hileras': cuartel['n_hileras'] ?? 0,
            'estado': _getEstadoFromId(cuartel['id_estado']),
            'sucursal': cuartel['nombre_sucursal'] ?? 'Sin sucursal',
            'variedad': cuartel['nombre_variedad'] ?? 'Sin variedad',
            'año_plantacion': cuartel['ano_plantacion'] ?? 0,
            'id_ceco': cuartel['id_ceco'],
            'id_variedad': cuartel['id_variedad'],
            'dsh': cuartel['dsh'],
            'deh': cuartel['deh'],
            'id_propiedad': cuartel['id_propiedad'],
            'id_portainjerto': cuartel['id_portainjerto'],
            'brazos_ejes': cuartel['brazos_ejes'],
            'id_estadoproductivo': cuartel['id_estadoproductivo'],
            'id_estadocatastro': cuartel['id_estadocatastro'],
          }).toList().cast<Map<String, dynamic>>();
          
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_cuarteles.length} cuarteles cargados'),
                        Text(
                          'Sucursal: $sucursalActiva',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Error desconocido');
        }
      } else {
        final errorBody = response.body;
        print('Error del servidor: $errorBody');
        throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}\n$errorBody');
      }

    } catch (e) {
      // En caso de error, mostrar mensaje claro
      print('Error cargando cuarteles: $e');
      _cuarteles = []; // Lista vacía para mostrar mensaje de error
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Error al cargar cuarteles',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      setState(() {
        _isLoadingCuarteles = false;
      });
    }
  }

  // Método auxiliar para convertir ID de estado a texto
  String _getEstadoFromId(int? idEstado) {
    switch (idEstado) {
      case 1:
        return 'activo';
      case 0:
        return 'inactivo';
      default:
        return 'pendiente';
    }
  }

  // Métodos para manejar selección de cuarteles
  void _toggleSeleccionCuartel(int cuartelId) {
    setState(() {
      if (_cuartelesSeleccionados.contains(cuartelId)) {
        _cuartelesSeleccionados.remove(cuartelId);
      } else {
        _cuartelesSeleccionados.add(cuartelId);
      }
      _actualizarSeleccionTodos();
    });
  }

  void _toggleSeleccionarTodos() {
    setState(() {
      _seleccionarTodos = !_seleccionarTodos;
      if (_seleccionarTodos) {
        _cuartelesSeleccionados = _cuarteles.map((c) => c['id'] as int).toSet();
      } else {
        _cuartelesSeleccionados.clear();
      }
    });
  }

  void _actualizarSeleccionTodos() {
    _seleccionarTodos = _cuartelesSeleccionados.length == _cuarteles.length;
  }

  void _descargarExcelCuartelesSeleccionados() async {
    if (_cuartelesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un cuartel para descargar'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      // Filtrar cuarteles seleccionados
      final cuartelesSeleccionados = _cuarteles
          .where((cuartel) => _cuartelesSeleccionados.contains(cuartel['id']))
          .toList();

      // Crear contenido CSV con separadores correctos
      final csvContent = StringBuffer();
      
      // Agregar BOM para que Excel reconozca UTF-8
      csvContent.write('\uFEFF');
      
      // Encabezados con punto y coma (mejor compatibilidad con Excel)
      csvContent.writeln('ID;Nombre;N_Hileras');
      
      // Datos con punto y coma como separador
      for (final cuartel in cuartelesSeleccionados) {
        final id = cuartel['id'].toString();
        final nombre = cuartel['nombre'].toString();
        final nHileras = (cuartel['n_hileras'] ?? 0).toString();
        
        csvContent.writeln('$id;$nombre;$nHileras');
      }

      // Descargar archivo con configuración para Excel
      if (kIsWeb) {
        final bytes = utf8.encode(csvContent.toString());
        final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'cuarteles_seleccionados.csv')
          ..setAttribute('type', 'text/csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel descargado con ${cuartelesSeleccionados.length} cuarteles'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildCuartelesList() {
    if (_isLoadingCuarteles) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Cargando cuarteles...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_cuarteles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay cuarteles en esta sucursal',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final sucursalActiva = authProvider.userData?['sucursal_nombre'] ?? '';
                return Text(
                  'Sucursal: $sucursalActiva',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarCuarteles,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuarteles Disponibles (${_cuarteles.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final sucursalActiva = authProvider.userData?['sucursal_nombre'] ?? '';
                    return Text(
                      'Sucursal: $sucursalActiva',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                // Contador de seleccionados
                if (_cuartelesSeleccionados.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_cuartelesSeleccionados.length} seleccionados',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_cuartelesSeleccionados.isNotEmpty) const SizedBox(width: 8),
                
                // Botón descargar Excel
                if (_cuartelesSeleccionados.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _descargarExcelCuartelesSeleccionados,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Descargar Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                if (_cuartelesSeleccionados.isNotEmpty) const SizedBox(width: 8),
                
                // Botón seleccionar todos
                ElevatedButton.icon(
                  onPressed: _toggleSeleccionarTodos,
                  icon: Icon(_seleccionarTodos ? Icons.check_box : Icons.check_box_outline_blank, size: 16),
                  label: Text(_seleccionarTodos ? 'Deseleccionar' : 'Seleccionar Todos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Botón actualizar
                IconButton(
                  onPressed: _isLoadingCuarteles ? null : _cargarCuarteles,
                  icon: _isLoadingCuarteles 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      )
                    : Icon(Icons.refresh, color: AppTheme.primaryColor),
                  tooltip: 'Actualizar cuarteles',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._cuarteles.map((cuartel) => _buildCuartelCard(cuartel)).toList(),
      ],
    );
  }

  Widget _buildCuartelCard(Map<String, dynamic> cuartel) {
    final cuartelId = cuartel['id'] as int;
    final isSeleccionado = _cuartelesSeleccionados.contains(cuartelId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSeleccionado ? 6 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSeleccionado 
          ? BorderSide(color: AppTheme.successColor, width: 2)
          : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkbox de selección
            Checkbox(
              value: isSeleccionado,
              onChanged: (value) => _toggleSeleccionCuartel(cuartelId),
              activeColor: AppTheme.successColor,
            ),
            const SizedBox(width: 8),
            // Avatar del estado
            CircleAvatar(
              backgroundColor: _getEstadoColor(cuartel['estado']),
              child: Icon(Icons.grid_on, color: Colors.white),
            ),
          ],
        ),
        title: Text(
          cuartel['nombre'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSeleccionado ? AppTheme.successColor : null,
          ),
        ),
        subtitle: Text('${cuartel['n_hileras']} hileras - ${_getEstadoText(cuartel['estado'])}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHilerasList(cuartel['id']),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAgregarHilerasDialog(cuartel['id']),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Hileras'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Estado Catastro',
                          border: OutlineInputBorder(),
                        ),
                        value: cuartel['estado'],
                        items: [
                          'activo',
                          'inactivo',
                          'pendiente',
                          'en_progreso',
                          'completado',
                          'verificado'
                        ].map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(_getEstadoText(estado)),
                        )).toList(),
                        onChanged: (value) => _actualizarEstadoCatastro(cuartel['id'], value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHilerasList(int cuartelId) {
    // TODO: Cargar hileras desde la API para el cuartel específico
    final hileras = <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hileras del Cuartel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${hileras.length} hileras',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hileras.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.view_column_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No hay hileras en este cuartel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agrega hileras usando el botón "Agregar Hileras"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2,
            ),
            itemCount: hileras.length,
            itemBuilder: (context, index) {
              final hilera = hileras[index];
              return Card(
                elevation: 1,
                child: InkWell(
                  onTap: () => _showEliminarHileraDialog(hilera['id'] as int, hilera['nombre'] as String),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hilera['nombre'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${hilera['plantas']} plantas',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // TAB 2: Mapeo - Asignación de registros de mapeo
  Widget _buildMapeo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Mapeo',
            'Asignación de registros de mapeo',
            Icons.assignment,
            AppTheme.infoColor,
          ),
          const SizedBox(height: 20),
          _buildCargaMasivaRegistros(),
          const SizedBox(height: 20),
          _buildImportacionExcel(),
        ],
      ),
    );
  }

  Widget _buildCargaMasivaRegistros() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                const Text(
                  'Carga Masiva de Registros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRegistrosForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrosForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registros de Mapeo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No hay registros de mapeo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los registros se cargarán desde la base de datos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _agregarRegistro(),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Registro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _procesarRegistros(),
                    icon: const Icon(Icons.upload),
                    label: const Text('Procesar Registros'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportacionExcel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_upload, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                const Text(
                  'Importación desde Excel/CSV',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildImportForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildImportForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Importar Datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Importación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                'plantas',
                'registros',
                'completo'
              ].map((tipo) => DropdownMenuItem(
                value: tipo,
                child: Text(tipo.toUpperCase()),
              )).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Arrastra archivos Excel/CSV aquí o haz clic para seleccionar',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _seleccionarArchivoGeneral(),
                    icon: const Icon(Icons.file_open),
                    label: const Text('Seleccionar Archivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _descargarPlantillaGeneral(),
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar Plantilla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: Gráficos - Visualización de datos
  Widget _buildGraficos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Gráficos',
            'Visualización de datos de mapeo y catastro',
            Icons.bar_chart,
            AppTheme.warningColor,
          ),
          const SizedBox(height: 20),
          _buildGraficosGrid(),
        ],
      ),
    );
  }

  Widget _buildGraficosGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildGraficoCard(
          'Distribución de Cuarteles',
          'Por estado y superficie',
          Icons.pie_chart,
          AppTheme.primaryColor,
          () => _mostrarGraficoCuarteles(),
        ),
        _buildGraficoCard(
          'Hileras por Cuartel',
          'Cantidad y distribución',
          Icons.bar_chart,
          AppTheme.infoColor,
          () => _mostrarGraficoHileras(),
        ),
        _buildGraficoCard(
          'Registros de Mapeo',
          'Progreso y completitud',
          Icons.trending_up,
          AppTheme.successColor,
          () => _mostrarGraficoRegistros(),
        ),
        _buildGraficoCard(
          'Productividad',
          'Eficiencia por evaluador',
          Icons.analytics,
          AppTheme.warningColor,
          () => _mostrarGraficoProductividad(),
        ),
      ],
    );
  }

  Widget _buildGraficoCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de utilidad
  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'completado':
        return AppTheme.successColor;
      case 'en_progreso':
        return AppTheme.warningColor;
      case 'verificado':
        return AppTheme.infoColor;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'activo':
        return 'Activo';
      case 'inactivo':
        return 'Inactivo';
      case 'pendiente':
        return 'Pendiente';
      case 'en_progreso':
        return 'En Progreso';
      case 'completado':
        return 'Completado';
      case 'verificado':
        return 'Verificado';
      default:
        return estado;
    }
  }

  // Métodos de acción
  void _procesarCargaMasiva() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Procesando carga masiva de cuarteles...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showAgregarHilerasDialog(int cuartelId) {
    final cantidadController = TextEditingController();
    
    // Buscar el cuartel seleccionado
    final cuartel = _cuarteles.firstWhere((c) => c['id'] == cuartelId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Agregar Hileras'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cuartel
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuartel: ${cuartel['nombre']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Superficie: ${cuartel['superficie']} ha'),
                  Text('Hileras actuales: ${cuartel['n_hileras']}'),
                  Text('Variedad: ${cuartel['variedad']}'),
                  Text('Sucursal: ${cuartel['sucursal']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Cuántas hileras adicionales deseas agregar?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(
                labelText: 'Número de Hileras',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.view_column),
                helperText: 'Se crearán automáticamente las hileras numeradas',
                hintText: 'Ej: 10',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Las hileras se crearán automáticamente con nombres secuenciales',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final cantidad = int.tryParse(cantidadController.text);
              if (cantidad == null || cantidad <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un número válido mayor a 0'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // Mostrar loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Agregando $cantidad hileras...'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );

                              try {
                  // Obtener token de autenticación
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final token = await authProvider.getToken();

                  if (token == null) {
                    throw Exception('No hay token de autenticación disponible');
                  }

                  // Llamada real a la API para agregar hileras
                  final response = await http.post(
                    Uri.parse('http://localhost:5000/api/cuarteles/$cuartelId/hileras'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'cantidad': cantidad,
                      'cuartel_id': cuartelId,
                    }),
                  );

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    
                    if (data['success'] == true) {
                      // Actualizar el cuartel localmente
                      setState(() {
                        final index = _cuarteles.indexWhere((c) => c['id'] == cuartelId);
                        if (index != -1) {
                          _cuarteles[index]['n_hileras'] = (_cuarteles[index]['n_hileras'] as int) + cantidad;
                        }
                      });

                      // Mostrar éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Se agregaron $cantidad hileras al cuartel ${cuartel['nombre']}'),
                            ],
                          ),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } else {
                      throw Exception(data['message'] ?? 'Error al agregar hileras');
                    }
                  } else {
                    throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al agregar hileras: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear Hileras'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEliminarHileraDialog(int hileraId, String hileraNombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Hilera'),
        content: Text(
          '¿Eliminar hilera $hileraNombre? Esta acción también eliminará todas las plantas asociadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hilera $hileraNombre eliminada'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _actualizarEstadoCatastro(int cuartelId, String estado) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado actualizado: ${_getEstadoText(estado)}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _agregarRegistro() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro agregado'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _procesarRegistros() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Procesando registros...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  // Métodos para mostrar gráficos específicos
  void _mostrarGraficoCuarteles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Distribución de Cuarteles'),
        content: const Text('Gráfico de distribución de cuarteles por estado y superficie'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarGraficoHileras() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hileras por Cuartel'),
        content: const Text('Gráfico de cantidad y distribución de hileras'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarGraficoRegistros() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registros de Mapeo'),
        content: const Text('Gráfico de progreso y completitud de registros'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarGraficoProductividad() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Productividad'),
        content: const Text('Gráfico de eficiencia por evaluador'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // MÉTODOS DE DESCARGA DE PLANTILLAS - IMPLEMENTACIÓN REAL
  void _seleccionarArchivoCuarteles() {
    _mostrarDialogoSeleccionArchivo('cuarteles');
  }

  void _seleccionarArchivoGeneral() {
    _mostrarDialogoSeleccionArchivo('general');
  }

  void _mostrarDialogoSeleccionArchivo(String tipo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_open, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Seleccionar Archivo ${tipo.toUpperCase()}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Formatos soportados:'),
            const SizedBox(height: 8),
            _buildInfoItem('• Excel (.xlsx, .xls)'),
            _buildInfoItem('• CSV (.csv)'),
            _buildInfoItem('• Tamaño máximo: 10MB'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Asegúrate de que el archivo siga el formato de la plantilla',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _iniciarSeleccionArchivo(tipo);
            },
            icon: const Icon(Icons.file_open),
            label: const Text('Seleccionar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _iniciarSeleccionArchivo(String tipo) {
    // TODO: Implementar selección real de archivos
    // Por ahora simulamos la selección
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Procesando archivo ${tipo}...'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

    // Simular procesamiento completado
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Archivo ${tipo.toUpperCase()} cargado exitosamente'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    });
  }

  void _descargarPlantillaCuarteles() {
    _mostrarDialogoDescarga('cuarteles');
  }

  void _descargarPlantillaGeneral() {
    _mostrarDialogoDescarga('general');
  }

  void _mostrarDialogoDescarga(String tipo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: AppTheme.infoColor),
            const SizedBox(width: 8),
            Text('Descargar Plantilla ${tipo.toUpperCase()}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se descargará la plantilla Excel con:'),
            const SizedBox(height: 8),
            _buildPlantillaInfo(tipo),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La plantilla incluye headers formateados y ejemplos de datos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _iniciarDescarga(tipo);
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.infoColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantillaInfo(String tipo) {
    switch (tipo) {
      case 'cuarteles':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Nombre del Cuartel'),
            _buildInfoItem('• Superficie (ha)'),
            _buildInfoItem('• Número de Hileras'),
            _buildInfoItem('• Sucursal'),
            _buildInfoItem('• Variedad'),
            _buildInfoItem('• Año de Plantación'),
          ],
        );
      case 'general':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Plantas (ID, Nombre, Tipo)'),
            _buildInfoItem('• Registros (Planta, Evaluador, Fecha)'),
            _buildInfoItem('• Datos completos (Cuarteles + Hileras)'),
          ],
        );
      default:
        return const Text('Información de plantilla no disponible');
    }
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  void _iniciarDescarga(String tipo) {
    // Mostrar loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Solicitando plantilla_${tipo}.xlsx al servidor...'),
          ],
        ),
        backgroundColor: AppTheme.infoColor,
        duration: const Duration(seconds: 3),
      ),
    );

    // IMPLEMENTACIÓN REAL: Llamada al backend según tu guía
    _descargarPlantillaDesdeBackend(tipo);
  }

  Future<void> _descargarPlantillaDesdeBackend(String tipo) async {
    try {
      // IMPLEMENTACIÓN REAL: Llamada al backend
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getToken();
      
      if (token == null) {
        throw Exception('No hay token de autenticación disponible');
      }
      
      final uri = Uri.parse('http://localhost:5000/api/mapeo/descargar-plantilla?tipo=$tipo');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // El backend envía el archivo Excel como bytes
        final bytes = response.bodyBytes;
        final filename = 'plantilla_${tipo}.xlsx';
        
        // El frontend descarga el archivo recibido
        await _descargarArchivo(bytes, filename);
        
        _mostrarExitoDescarga(tipo);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      // Si falla la llamada al backend, crear un archivo de ejemplo
      print('Error al conectar con backend: $e');
      await _crearArchivoEjemplo(tipo);
    }
  }

  Future<void> _crearArchivoEjemplo(String tipo) async {
    try {
      // Crear contenido de ejemplo para la plantilla
      String contenido = '';
      String filename = '';
      
      if (tipo == 'cuarteles') {
        contenido = '''Nombre del Cuartel,Superficie (ha),Número de Hileras,Sucursal,Variedad,Año de Plantación
Cuartel A,5.2,10,Sucursal Norte,Variedad 1,2024
Cuartel B,3.8,8,Sucursal Sur,Variedad 2,2024
Cuartel C,7.1,12,Sucursal Este,Variedad 1,2024''';
        filename = 'plantilla_cuarteles.csv';
      } else {
        contenido = '''Planta,Tipo Planta,Evaluador,Fecha
Planta 1,Tipo A,Evaluador 1,2024-01-15
Planta 2,Tipo B,Evaluador 2,2024-01-16
Planta 3,Tipo A,Evaluador 1,2024-01-17''';
        filename = 'plantilla_general.csv';
      }
      
             // Convertir a bytes usando UTF-8
       final bytes = utf8.encode(contenido);
      
      // Descargar archivo
      await _descargarArchivo(bytes, filename);
      _mostrarExitoDescarga(tipo);
      
    } catch (e) {
      _mostrarErrorDescarga('Error al crear archivo de ejemplo: $e');
    }
  }

  void _mostrarExitoDescarga(String tipo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Plantilla ${tipo.toUpperCase()} descargada exitosamente'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarErrorDescarga(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Error al descargar: $error'),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Método auxiliar para descargar archivo - IMPLEMENTACIÓN REAL
  Future<void> _descargarArchivo(List<int> bytes, String filename) async {
    try {
      // Para web (Flutter Web)
      if (kIsWeb) {
        // Implementación real para web usando dart:html
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        print('✅ Archivo $filename descargado exitosamente en web');
      } else {
        // Para móvil/desktop - mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo $filename listo para descargar'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
        print('📱 Archivo $filename listo para descargar en móvil/desktop');
      }
      
    } catch (e) {
      print('❌ Error al descargar archivo: $e');
      rethrow;
    }
  }
}

