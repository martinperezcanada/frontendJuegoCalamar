import 'package:flutter/material.dart';
import 'package:juegocalamar_frontend/provider/user_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await userProvider.loadToken();

    if (mounted) {
      if (userProvider.token != null) {
        print('✅ Usuario autenticado con token: ${userProvider.token}');
        Navigator.pushReplacementNamed(context, 'gameSelection');
      } else {
        print('🚫 Usuario no autenticado');
        Navigator.pushReplacementNamed(context, 'login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'http://10.0.2.2:3000/uploads/logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            const Text(
              'Squid Game Fútbol',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '¿Quién será el último en pie?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color.fromARGB(255, 229, 7, 7),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
