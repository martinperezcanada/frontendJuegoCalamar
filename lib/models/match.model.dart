class Match {
  final String team1;
  final String team2;
  final DateTime? fecha;
  final int jornada;
  final String? resultado;

  Match({
    required this.team1,
    required this.team2,
    required this.fecha,
    required this.jornada,
    this.resultado,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      team1: json['team1']['name'],
      team2: json['team2']['name'],
      jornada: json['jornada'] ?? 0,
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha']).toLocal()
          : null,
      resultado: json['resultado'],
    );
  }

  static String formatFecha(DateTime? fecha) {
    if (fecha == null) return 'SIN HORA';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')} '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  static String formatHora(DateTime? fecha) {
    if (fecha == null) return '';
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}
