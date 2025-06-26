import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LigaProvider with ChangeNotifier {
  String? _ligaSeleccionada;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? get ligaSeleccionada => _ligaSeleccionada;

  Future<void> cargarLigaSeleccionada() async {
    _ligaSeleccionada = await _storage.read(key: 'ligaSeleccionada');
    notifyListeners();
  }

  Future<void> establecerLiga(String liga) async {
    _ligaSeleccionada = liga;
    await _storage.write(key: 'ligaSeleccionada', value: liga);
    notifyListeners();
  }
}
