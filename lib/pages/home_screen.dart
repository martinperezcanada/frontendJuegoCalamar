import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juegocalamar_frontend/models/match.model.dart';
import 'package:juegocalamar_frontend/pages/teamSelection_screen.dart';
import 'package:juegocalamar_frontend/provider/match_provider.dart';
import 'package:juegocalamar_frontend/provider/liga_provider.dart';
import 'package:juegocalamar_frontend/provider/user_provider.dart';
import 'package:juegocalamar_frontend/widgets/customNavBar_widget.dart';
import 'package:juegocalamar_frontend/widgets/matchCardSkeleton_widget.dart';
import 'package:juegocalamar_frontend/widgets/matchCard_widget.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 1;
  int get currentAmount =>
      Provider.of<UserProvider>(context).userCountInLiga * 9;

  bool get wantKeepAlive => true;

  bool _isAnimating = false;
  Widget? _overlayAnimation;

  @override
  void initState() {
    super.initState();

    final ligaProvider = Provider.of<LigaProvider>(context, listen: false);
    ligaProvider.cargarLigaSeleccionada().then((_) {
      final liga = ligaProvider.ligaSeleccionada;
      print("🎮 Liga seleccionada en HomeScreen: $liga");

      final matchProvider = Provider.of<MatchProvider>(context, listen: false);
      matchProvider.loadMatches(liga: liga);
      matchProvider.cargarJornadasDisponibles(liga ?? ''); // ✅ necesario
      Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadUserCountInLiga(liga ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final matchProvider = Provider.of<MatchProvider>(context);
    final liga = Provider.of<LigaProvider>(context).ligaSeleccionada;
    final userCount = Provider.of<UserProvider>(context).userCountInLiga;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 16.0,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 20.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              child: Divider(color: Colors.white, thickness: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "$currentAmount€",
                              style: GoogleFonts.roboto(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 105, 240, 174),
                              ),
                            ),

                            const SizedBox(width: 10),
                            const SizedBox(
                              width: 20,
                              child: Divider(color: Colors.white, thickness: 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "$userCount usuarios en pie",
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
                  child: SizedBox(
                    height: 50,
                    child: Consumer<MatchProvider>(
                      builder: (context, matchProvider, child) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: matchProvider.jornadasDisponibles.length,
                          itemBuilder: (context, index) {
                            final jornada =
                                matchProvider.jornadasDisponibles[index];
                            final esSeleccionada =
                                matchProvider.jornadaSeleccionada == jornada;

                            return GestureDetector(
                              onTap: () {
                                matchProvider.seleccionarJornada(
                                  jornada,
                                  liga: liga ?? '',
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: esSeleccionada
                                      ? const Color.fromARGB(255, 105, 240, 174)
                                      : Colors.grey[800],
                                  shape: BoxShape.circle,
                                  boxShadow: esSeleccionada
                                      ? [
                                          BoxShadow(
                                            color: Colors.greenAccent
                                                .withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    '$jornada',
                                    style: TextStyle(
                                      color: esSeleccionada
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                Expanded(
                  child: matchProvider.isLoading
                      ? GridView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: 6,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.8,
                              ),
                          itemBuilder: (context, index) =>
                              const MatchCardSkeleton(),
                        )
                      : matchProvider.matches.isEmpty
                      ? const Center(child: Text('No hay partidos disponibles'))
                      : RefreshIndicator(
                          onRefresh: () async {
                            await Provider.of<MatchProvider>(
                              context,
                              listen: false,
                            ).loadMatches(liga: liga);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 2.8,
                                  ),
                              itemCount: matchProvider.matches.length,
                              itemBuilder: (context, index) {
                                final match = matchProvider.matches[index];
                                final team1Asset =
                                    MatchProvider.teamNameToAsset(match.team1);
                                final team2Asset =
                                    MatchProvider.teamNameToAsset(match.team2);
                                final fechaDelPartido = DateTime.parse(
                                  "2025-06-18 19:00:00",
                                );

                                return GestureDetector(
                                  onTap: () async {
                                    final selectedTeam = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TeamSelectionScreen(
                                          team1: team1Asset,
                                          team2: team2Asset,
                                          ligaName: liga ?? 'Liga Desconocida',
                                          fecha:
                                              fechaDelPartido, // ✅ aquí pasás la fecha
                                        ),
                                      ),
                                    );

                                    if (selectedTeam != null) {
                                      print(
                                        "Equipo seleccionado: $selectedTeam",
                                      );
                                      Provider.of<MatchProvider>(
                                        context,
                                        listen: false,
                                      ).loadMatches(liga: liga);
                                    }
                                  },
                                  child: MatchCard(
                                    team1: team1Asset,
                                    team2: team2Asset,
                                    date: match.fecha != null
                                        ? '${match.fecha!.day.toString().padLeft(2, '0')}/${match.fecha!.month.toString().padLeft(2, '0')}'
                                        : '',
                                    time: Match.formatHora(match.fecha),
                                    resultado: match.resultado,
                                    equiposSeleccionados: matchProvider
                                        .equiposSeleccionados, // <-- Aquí debes pasar la lista
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
            if (_isAnimating && _overlayAnimation != null) _overlayAnimation!,
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(selectedIndex: _selectedIndex),
    );
  }
}
