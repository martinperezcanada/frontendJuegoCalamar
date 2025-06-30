import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class TeamSelectionScreen extends StatefulWidget {
  final String team1;
  final String team2;
  final String ligaName;
  final DateTime fecha;

  const TeamSelectionScreen({
    super.key,
    required this.team1,
    required this.team2,
    required this.ligaName,
    required this.fecha,
  });

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  final storage = FlutterSecureStorage();
  String? userId;
  bool datosCargados = false;
  List<String> equiposSeleccionados = [];

  final Color mainGreen = const Color.fromARGB(255, 105, 240, 174);

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await initializeDateFormatting('es_ES', null);
    Intl.defaultLocale = 'es_ES';
    await cargarDatosUsuario();
  }

  Future<void> cargarDatosUsuario() async {
    final id = await storage.read(key: 'user_id');
    setState(() {
      userId = id;
      datosCargados = true;
    });
    if (userId != null) {
      await obtenerEquiposSeleccionados();
    }
  }

  Future<void> obtenerEquiposSeleccionados() async {
    final url = Uri.parse(
      'https://backend-juegocalamar.onrender.com/users/$userId',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ligas = data['ligasRegistradas'] as List<dynamic>;
        final liga = ligas.firstWhere(
          (l) => l['liga'] == widget.ligaName,
          orElse: () => null,
        );
        if (liga != null && liga['equiposSeleccionados'] != null) {
          setState(() {
            equiposSeleccionados = List<String>.from(
              liga['equiposSeleccionados'],
            );
          });
        }
      } else {
        print('Error al obtener usuario: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar datos del usuario')),
        );
      }
    } catch (e) {
      print('Error de red al obtener equipos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de red al obtener equipos')),
      );
    }
  }

  Future<void> eliminarEquipoDeLiga(String equipoId) async {
    if (userId == null) return;

    final liga = widget.ligaName;
    final url = Uri.parse(
      'https://backend-juegocalamar.onrender.com/users/$userId/ligas/$liga/equipos/$equipoId',
    );

    try {
      final response = await http.delete(url);
      if (response.statusCode != 200) {
        print('Error al eliminar el equipo: ${response.body}');
      }
    } catch (e) {
      print('Error de red al eliminar equipo: $e');
    }
  }

  Future<void> incrementarSelectedCount(String equipoId) async {
    final url = Uri.parse(
      'https://backend-juegocalamar.onrender.com/teams/name/$equipoId/increment',
    );
    try {
      final response = await http.post(url);
      if (response.statusCode != 200) {
        print('Error al incrementar selectedCount: ${response.body}');
      }
    } catch (e) {
      print('Error de red al incrementar selectedCount: $e');
    }
  }

  Future<void> decrementarSelectedCount(String equipoId) async {
    final url = Uri.parse(
      'https://backend-juegocalamar.onrender.com/teams/name/$equipoId/decrement',
    );
    try {
      final response = await http.post(url);
      if (response.statusCode != 200) {
        print('Error al decrementar selectedCount: ${response.body}');
      }
    } catch (e) {
      print('Error de red al decrementar selectedCount: $e');
    }
  }

  String extraerNombreEquipoDesdeUrl(String url) {
    return url.split('/').last.split('.').first;
  }

  void onTeamTap(String teamUrl) async {
    if (userId == null) return;

    final equipoId = extraerNombreEquipoDesdeUrl(teamUrl);
    final yaSeleccionado = equiposSeleccionados.contains(equipoId);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 66, 64, 64),
        title: Text(
          yaSeleccionado ? '¿Deseleccionar equipo?' : '¿Seleccionar equipo?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          yaSeleccionado
              ? '¿Estás seguro de que quieres deseleccionar este equipo?'
              : '¿Estás seguro de que quieres seleccionar este equipo?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sí', style: TextStyle(color: mainGreen)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    if (yaSeleccionado) {
      await eliminarEquipoDeLiga(equipoId);
      await decrementarSelectedCount(equipoId);
      setState(() {
        equiposSeleccionados.remove(equipoId);
      });
    } else {
      await registrarEquipoEnLiga(equipoId);
      await incrementarSelectedCount(equipoId);
      setState(() {
        equiposSeleccionados.add(equipoId);
      });
    }
  }

  Future<bool> registrarEquipoEnLiga(String equipoId) async {
    if (userId == null) return false;

    final liga = widget.ligaName;
    final url = Uri.parse(
      'https://backend-juegocalamar.onrender.com/users/$userId/ligas/$liga/equipos/$equipoId',
    );

    try {
      final response = await http.patch(url);
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al registrar el equipo: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red: $e');
      return false;
    }
  }

  bool estaSeleccionado(String teamUrl) {
    return equiposSeleccionados.contains(extraerNombreEquipoDesdeUrl(teamUrl));
  }

  @override
  Widget build(BuildContext context) {
    final fecha = widget.fecha;
    final diaSemana = DateFormat.EEEE().format(fecha).toUpperCase();
    final fechaCompleta = DateFormat('d MMMM y').format(fecha);
    final hora = DateFormat('hh:mm a').format(fecha);

    if (!datosCargados) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Flecha de volver
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Contenido principal
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 40,
                    ), // Espacio para no tapar la flecha
                    Text(
                      widget.ligaName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "MATCH DAY",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => onTeamTap(widget.team1),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: estaSeleccionado(widget.team1)
                                        ? mainGreen
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.network(
                                  widget.team1,
                                  width: 90,
                                  height: 90,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              extraerNombreEquipoDesdeUrl(widget.team1),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 30),
                        Text(
                          "VS",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 30),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => onTeamTap(widget.team2),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: estaSeleccionado(widget.team2)
                                        ? mainGreen
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.network(
                                  widget.team2,
                                  width: 90,
                                  height: 90,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              extraerNombreEquipoDesdeUrl(widget.team2),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: mainGreen.withOpacity(0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                diaSemana,
                                style: TextStyle(
                                  color: mainGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fechaCompleta,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hora,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: mainGreen.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.event_available,
                              color: mainGreen,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
