import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:juegocalamar_frontend/models/user.model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;
  String? get token => _user?.token;
  String? get userId => _user?.id;

  final String _baseUrl = 'http://10.0.2.2:3000/auth';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 🔢 NUEVO: Contador de usuarios por liga
  int _userCountInLiga = 0;
  int get userCountInLiga => _userCountInLiga;

  // Login
  Future<void> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    if (kDebugMode) print('🔐 Enviando login con email: $email');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final responseBody = jsonDecode(response.body);

    if (kDebugMode) {
      print('📥 Respuesta del login: $responseBody');
      print('📤 Código HTTP: ${response.statusCode}');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = responseBody['token'] ?? '';
      final userJson = responseBody['user'] ?? {};

      if (token.isEmpty) {
        throw Exception('Token no recibido en la respuesta del login');
      }

      _user = User.fromJson({...userJson, 'token': token});
      await _secureStorage.write(key: 'auth_token', value: token);
      await _secureStorage.write(key: 'user_id', value: _user!.id);

      if (kDebugMode) {
        print(
          '✅ Login exitoso. Usuario: ${_user!.name} ${_user!.lastName}, email: ${_user!.email}',
        );
      }

      notifyListeners();
    } else {
      throw Exception(responseBody['message'] ?? 'Error al iniciar sesión');
    }
  }

  // Registro
  Future<void> register(
    String name,
    String lastName,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$_baseUrl/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'lastName': lastName,
        'email': email,
        'password': password,
      }),
    );

    final responseBody = jsonDecode(response.body);

    if (kDebugMode) print('📥 Respuesta del registro: $responseBody');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final token = responseBody['token'] ?? '';

      if (token.isEmpty) {
        throw Exception('Token no recibido en la respuesta del registro');
      }

      await _secureStorage.write(key: 'auth_token', value: token);

      Map<String, dynamic> payload = Jwt.parseJwt(token);
      final userId = payload['sub'] ?? payload['_id'] ?? payload['id'];
      await _secureStorage.write(key: 'user_id', value: userId);

      if (userId == null) {
        throw Exception('userId no encontrado en el token');
      }

      final url = Uri.parse('http://10.0.2.2:3000/users/$userId');
      final responseUser = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (responseUser.statusCode == 200) {
        final dataUser = jsonDecode(responseUser.body);
        _user = User.fromJson({...dataUser, 'token': token});
        notifyListeners();
      } else {
        throw Exception(
          'Error al cargar datos del usuario después del registro',
        );
      }
    }
  }

  // Cargar token y refrescar datos
  Future<void> loadToken() async {
    final storedToken = await _secureStorage.read(key: 'auth_token');
    print('🔐 Token almacenado leído: $storedToken');

    if (storedToken != null && !Jwt.isExpired(storedToken)) {
      try {
        Map<String, dynamic> payload = Jwt.parseJwt(storedToken);
        final userId = payload['sub'] ?? payload['_id'] ?? payload['id'];

        if (userId != null) {
          _user = User(
            id: userId,
            name: '',
            lastName: '',
            email: '',
            token: storedToken,
          );

          print('✅ Token válido, userId: $userId');
          await _secureStorage.write(key: 'user_id', value: userId);
          await fetchUserDetails();
          notifyListeners();
          return;
        } else {
          print('❌ Token no tiene userId en payload: $payload');
        }
      } catch (e) {
        print('❌ Error al parsear token: $e');
      }
    } else {
      print('⚠️ Token nulo o expirado');
    }

    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_id');
    _user = null;
    notifyListeners();
  }

  // Obtener datos completos del usuario
  Future<void> fetchUserDetails() async {
    if (userId == null || token == null) {
      if (kDebugMode) print('❗ Falta userId o token para cargar usuario');
      return;
    }

    final url = Uri.parse('http://10.0.2.2:3000/users/$userId');
    if (kDebugMode) print('📡 Cargando detalles del usuario desde: $url');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (kDebugMode) print('✅ Datos del usuario recibidos: $data');

      _user = User.fromJson({...data, 'token': token});
      notifyListeners();
    } else {
      if (kDebugMode) {
        print('❌ Error al cargar datos del usuario: ${response.body}');
      }
      throw Exception('Error al cargar los datos del usuario');
    }
  }

  // Logout
  Future<void> logout() async {
    if (kDebugMode) print('🔒 Cerrando sesión');
    _user = null;
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_id');
    notifyListeners();
  }

  Future<void> loadUserCountInLiga(String liga) async {
    try {
      final url = Uri.parse('http://10.0.2.2:3000/users/count/by-liga/$liga');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        _userCountInLiga = int.parse(res.body);
        if (kDebugMode) {
          print('📊 Usuarios registrados en $liga: $_userCountInLiga');
        }
        notifyListeners();
      } else {
        if (kDebugMode) {
          print('⚠️ Error al cargar conteo de usuarios: ${res.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error al obtener usuarios por liga: $e');
    }
  }
}
