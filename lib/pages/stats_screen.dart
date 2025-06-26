import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:juegocalamar_frontend/provider/liga_provider.dart';
import 'package:juegocalamar_frontend/provider/match_provider.dart';
import 'package:juegocalamar_frontend/widgets/customNavBar_widget.dart';

class StatsScreen extends StatefulWidget {
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final int _selectedIndex = 0;
  final int jornadaActual = 1;

  late Future<List<Map<String, dynamic>>> _futureEquipos;

  @override
  void initState() {
    super.initState();
    _futureEquipos = _cargarEquiposFiltrados();
  }

  Future<List<Map<String, dynamic>>> _cargarEquiposFiltrados() async {
    final ligaProvider = Provider.of<LigaProvider>(context, listen: false);
    await ligaProvider.cargarLigaSeleccionada();

    final liga = ligaProvider.ligaSeleccionada;
    print("[LOG] Liga seleccionada desde storage: $liga");

    final equipos = await MatchProvider().fetchAllTeams();
    print("[LOG] Total de equipos recibidos: ${equipos.length}");

    for (var e in equipos) {
      print("[LOG] Equipo: ${e['name']} | Liga: ${e['liga']}");
    }

    final filtrados = equipos.where((equipo) {
      final mismoNombre = equipo['liga'] == liga;
      print(
        "[LOG] Comparando equipo '${equipo['name']}' con liga '${equipo['liga']}' == '$liga' => $mismoNombre",
      );
      return mismoNombre;
    }).toList();

    print("[LOG] Equipos filtrados por liga '$liga': ${filtrados.length}");

    return filtrados;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Estadísticas Jornada $jornadaActual'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureEquipos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final equipos = snapshot.data ?? [];

          if (equipos.isEmpty) {
            return const Center(child: Text('No hay equipos para esta liga.'));
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: equipos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final equipo = equipos[index];
                final String imageUrl = MatchProvider.teamNameToAsset(
                  equipo['name'],
                );

                final selectedCount =
                    equipo['selectedCount']?[jornadaActual.toString()] ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 60,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          equipo['name'],
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedCount.toString(),
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: CustomNavBar(selectedIndex: _selectedIndex),
    );
  }
}
