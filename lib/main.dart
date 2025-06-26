import 'package:flutter/material.dart';
import 'package:juegocalamar_frontend/pages/register_screen.dart';
import 'package:juegocalamar_frontend/pages/userSettings_screen.dart';
import 'package:juegocalamar_frontend/provider/liga_provider.dart';
import 'package:juegocalamar_frontend/provider/match_provider.dart';
import 'package:juegocalamar_frontend/provider/user_provider.dart';
import 'package:juegocalamar_frontend/utils/helpers/navigation_helper.dart';
import 'package:juegocalamar_frontend/values/app_theme.dart';
import 'package:provider/provider.dart';

import 'package:juegocalamar_frontend/pages/home_screen.dart';
import 'package:juegocalamar_frontend/pages/splash_screen.dart';
import 'package:juegocalamar_frontend/pages/login_screen.dart';
import 'package:juegocalamar_frontend/pages/gameSelection_screen.dart';

void main() => runApp(const AppState());

class AppState extends StatelessWidget {
  const AppState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LigaProvider()),
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  Future<bool> checkLogin(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadToken();
    return userProvider.token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkLogin(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }

        final isLoggedIn = snapshot.data ?? false;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'JuegoCalamar',
          navigatorKey: NavigationHelper.key,
          initialRoute: isLoggedIn ? 'gameSelection' : 'login',
          routes: {
            'home': (_) => const HomeScreen(),
            'splash': (_) => const SplashScreen(),
            'login': (_) => const LoginScreen(),
            'register': (_) => const RegisterScreen(),
            'gameSelection': (_) => const GameSelectionScreen(),
            'userSettings': (_) => const UserSettingsScreen(),
          },
          theme: AppTheme.themeData.copyWith(
            appBarTheme: const AppBarTheme(color: Colors.indigo),
          ),
        );
      },
    );
  }
}
