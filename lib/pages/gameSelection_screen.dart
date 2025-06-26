import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:juegocalamar_frontend/pages/home_screen.dart';
import 'package:juegocalamar_frontend/provider/liga_provider.dart';
import 'package:provider/provider.dart';

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({Key? key}) : super(key: key);

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  List<dynamic> ligasConEquipos = [];
  Set<String> ligasUsuario = {};
  bool loading = true;

  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final userId = await storage.read(key: 'user_id');
      final token = await storage.read(key: 'auth_token');

      final responseLigas = await http.get(
        Uri.parse('http://10.0.2.2:3000/ligas-equipos'),
      );

      if (responseLigas.statusCode == 200) {
        ligasConEquipos = json.decode(responseLigas.body);
      } else {
        throw Exception('Error al cargar ligas');
      }

      if (userId != null && token != null) {
        final responseUser = await http.get(
          Uri.parse('http://10.0.2.2:3000/users/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (responseUser.statusCode == 200) {
          final userData = json.decode(responseUser.body);
          final equipos = userData['equipos'] ?? [];
          ligasUsuario = equipos
              .map<String>((e) => e['liga'] as String)
              .toSet();
        }
      }

      setState(() => loading = false);
    } catch (e) {
      print('❌ Error en fetchData: $e');
      setState(() => loading = false);
    }
  }

  String getLogoForLiga(String liga) {
    final cleanLiga = liga.trim().toLowerCase();

    if (cleanLiga.contains('laliga')) {
      return 'http://10.0.2.2:3000/uploads/laliga.png';
    } else if (cleanLiga.contains('premier')) {
      return 'http://10.0.2.2:3000/uploads/premier.png';
    } else if (cleanLiga.contains('mundialclubes')) {
      return 'http://10.0.2.2:3000/uploads/mundialClubes.png';
    } else if (cleanLiga.contains('serie')) {
      return 'http://10.0.2.2:3000/uploads/seriea.png';
    } else {
      return 'http://10.0.2.2:3000/uploads/default.png';
    }
  }

  String formatLigaName(String rawName) {
    final clean = rawName.trim().toLowerCase();

    if (clean.contains('laliga')) return 'LA LIGA';
    if (clean.contains('premier')) return 'PREMIER LEAGUE';
    if (clean.contains('mundialclubes')) return 'MUNDIAL de CLUBES';
    if (clean.contains('serie')) return 'SERIE A';

    return rawName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccione su liga'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ligasConEquipos.length,
              itemBuilder: (context, index) {
                final liga = ligasConEquipos[index]['liga'];
                final logoPath = getLogoForLiga(liga);
                final ligaFormatted = formatLigaName(liga);

                final esMundialClubes = liga.trim().toLowerCase().contains(
                  'mundialclubes',
                );
                final yaUnido = ligasUsuario.contains(liga);

                return GestureDetector(
                  onTap: () async {
                    if (!esMundialClubes) return;

                    final storage = FlutterSecureStorage();

                    final userId = await storage.read(key: 'user_id');
                    final token = await storage.read(key: 'auth_token');
                    Provider.of<LigaProvider>(
                      context,
                      listen: false,
                    ).establecerLiga(liga);

                    if (userId == null || token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario no autenticado.'),
                        ),
                      );
                      return;
                    }

                    // Si aún no está unido a la liga, hace el PATCH
                    if (!yaUnido) {
                      final response = await http.patch(
                        Uri.parse(
                          'http://10.0.2.2:3000/users/$userId/ligas/$liga',
                        ),
                        headers: {'Authorization': 'Bearer $token'},
                      );

                      if (response.statusCode != 200) {
                        final errorData = json.decode(response.body);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${errorData['message']}'),
                          ),
                        );
                        return;
                      }
                    }

                    // Guardar la liga seleccionada para persistencia
                    await storage.write(key: 'ligaSeleccionada', value: liga);

                    // Ir a HomeScreen con la liga seleccionada
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },

                  child: Opacity(
                    opacity: esMundialClubes ? 1.0 : 0.5,
                    child: Container(
                      height: 140,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            bottom: -10,
                            right: 10,
                            child: Opacity(
                              opacity: 0.15,
                              child: Image.network(
                                logoPath,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  esMundialClubes
                                      ? ligaFormatted
                                      : 'Próximamente...',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (yaUnido)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 28,
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
              },
            ),
    );
  }
}
