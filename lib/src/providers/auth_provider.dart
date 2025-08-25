import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get userData => _user;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userData = prefs.getString('user');

      if (token != null && userData != null) {
        _token = token;
        _user = jsonDecode(userData);
        _isAuthenticated = true;
      }
    } catch (e) {
      print('Error loading auth state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> login(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Llamada real a la API de login
      final loginData = {
        'usuario': username,
        'clave': password,
      };
      
      print('Enviando datos de login: $loginData');
      
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(loginData),
      );

      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Estructura correcta según la respuesta del backend
          _token = data['access_token'];
          _user = {
            'usuario': data['usuario'],
            'nombre': data['nombre'],
            'id_sucursal': data['id_sucursal'],
            'sucursal_nombre': data['sucursal_nombre'],
            'id_rol': data['id_rol'],
            'id_perfil': data['id_perfil'],
          };
          _isAuthenticated = true;

          // Guardar en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('user', jsonEncode(_user));

          print('Login exitoso para usuario: ${_user?['usuario']} (${_user?['nombre']})');
          print('Sucursal: ${_user?['sucursal_nombre']}');
          return true;
        } else {
          print('Login failed: ${data['message'] ?? 'Error desconocido'}');
          return false;
        }
      } else {
        print('Login failed with status: ${response.statusCode}');
        print('Error response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');

      _token = null;
      _user = null;
      _isAuthenticated = false;
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    await _loadAuthState();
  }
}
