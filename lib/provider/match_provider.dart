import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juegocalamar_frontend/models/match.model.dart';

class MatchProvider with ChangeNotifier {
  List<Match> _matches = [];
  bool _isLoading = false;
  String _error = '';
  int _defaultJornada = 1;

  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get defaultJornada => _defaultJornada;

  List<String> _equiposSeleccionados = [];
  List<String> get equiposSeleccionados => _equiposSeleccionados;

  List<int> _jornadasDisponibles = [];
  int _jornadaSeleccionada = 1;

  List<int> get jornadasDisponibles => _jornadasDisponibles;
  int get jornadaSeleccionada => _jornadaSeleccionada;

  Future<void> fetchEquiposSeleccionados(String userId, String ligaId) async {
    final url =
        'http://10.0.2.2:3000/users/$userId/$ligaId/equiposSeleccionados';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _equiposSeleccionados = data
            .map((e) => e.toString().toLowerCase())
            .toList();
      } else {
        _equiposSeleccionados = [];
      }
    } catch (e) {
      _equiposSeleccionados = [];
    }

    notifyListeners();
  }

  Future<void> fetchMatches(int jornada, {String? liga}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final url = liga == null
          ? 'http://10.0.2.2:3000/teams/jornada/$jornada'
          : 'http://10.0.2.2:3000/teams/jornada/$jornada/liga/$liga';

      print('Fetching matches from $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _matches = data.map((json) => Match.fromJson(json)).toList();
      } else {
        _error = 'Error al cargar los partidos: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'No se pudo conectar al servidor: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMatches({String? liga}) async {
    await determineCurrentJornada();
    await fetchMatches(_defaultJornada, liga: liga);
    _jornadaSeleccionada = _defaultJornada;
  }

  Future<void> determineCurrentJornada() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/teams'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final now = DateTime.now();
        Map<int, List<Match>> groupedByJornada = {};

        for (var json in data) {
          Match match = Match.fromJson(json);
          if (match.fecha != null) {
            groupedByJornada.putIfAbsent(match.jornada, () => []).add(match);
          }
        }

        final jornadasOrdenadas = groupedByJornada.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        int jornadaEncontrada = _defaultJornada;
        for (var entry in jornadasOrdenadas) {
          final hasFutureMatch = entry.value.any((m) => m.fecha!.isAfter(now));
          final allBefore = entry.value.every((m) => m.fecha!.isBefore(now));

          if (hasFutureMatch || (!hasFutureMatch && !allBefore)) {
            jornadaEncontrada = entry.key;
            break;
          }
        }

        _defaultJornada = jornadaEncontrada;
      } else {
        _error = 'Error al obtener jornada actual: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error al obtener jornada actual: $e';
    }
  }

  Future<void> cargarJornadasDisponibles(String liga) async {
    print('🔄 Cargando jornadas disponibles para la liga: $liga');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/teams/liga/$liga'),
      );

      print('📡 Estado de la respuesta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📦 Partidos recibidos: ${data.length}');

        final jornadasSet = <int>{};
        for (var json in data) {
          final match = Match.fromJson(json);
          print('➡️ Partido jornada: ${match.jornada}');
          jornadasSet.add(match.jornada);
        }

        _jornadasDisponibles = jornadasSet.toList()..sort();
        print('✅ Jornadas disponibles: $_jornadasDisponibles');

        notifyListeners();
      } else {
        print('❌ Error en la respuesta: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Excepción al cargar jornadas: $e');
    }
  }

  Future<void> seleccionarJornada(int jornada, {required String liga}) async {
    _jornadaSeleccionada = jornada;
    notifyListeners();
    await fetchMatches(jornada, liga: liga);
  }

  Future<List<Map<String, dynamic>>> fetchAllTeams() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/teams'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception("No se pudieron cargar los equipos");
    }
  }

  static String teamNameToAsset(String name) {
    String lower = name.toLowerCase().replaceAll(' ', '');

    Map<String, String> mapping = {
      'realbetis': 'betis',
      'realvalladolid': 'valladolid',
      'realsociedad': 'realSociedad',
      'realmadrid': 'realMadrid',
      'atleticomadrid': 'atleticoMadrid',
      'athleticclub': 'athleticBilbao',
      'laspalmas': 'lasPalmas',
    };

    String fileName = mapping[lower] ?? lower;
    return 'http://10.0.2.2:3000/uploads/$fileName.png';
  }
}
