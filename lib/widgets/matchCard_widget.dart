import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchCard extends StatelessWidget {
  final String team1;
  final String team2;
  final String time;
  final String date;
  final String? resultado;
  final List<String> equiposSeleccionados;

  const MatchCard({
    Key? key,
    required this.team1,
    required this.team2,
    required this.time,
    required this.date,
    required this.equiposSeleccionados,
    this.resultado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasResultado = resultado != null && resultado!.trim().isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey('$team1-$team2-$date-$time-$resultado'),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 2),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTeamImage(
                team1,
                equiposSeleccionados.contains(team1.toLowerCase()),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: hasResultado
                    ? [
                        Text(
                          resultado!,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ]
                    : [
                        Text(
                          date,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
              ),
              _buildTeamImage(team2, equiposSeleccionados.contains(team2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamImage(String url, bool isSelected) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholderFadeInDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            if (isSelected)
              CustomPaint(
                size: const Size(40, 40),
                painter: _DiagonalLinePainter(),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 3;

    // Línea diagonal de arriba izquierda a abajo derecha
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
