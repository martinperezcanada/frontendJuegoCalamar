import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juegocalamar_frontend/provider/user_provider.dart';
import 'package:juegocalamar_frontend/values/app_routes.dart';
import 'package:juegocalamar_frontend/widgets/customNavBar_widget.dart';
import 'package:provider/provider.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.fetchUserDetails();
    } catch (e) {
      print('Error al obtener usuario: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    final textStyleSubtitle = GoogleFonts.roboto(
      fontSize: 14,
      color: Colors.grey[600],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomNavBar(selectedIndex: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 35),
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.lightBlue,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Editar foto"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.lightBlue,
                          textStyle: GoogleFonts.roboto(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${user?.name ?? ''} ${user?.lastName ?? ''}",
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(user?.email ?? '', style: textStyleSubtitle),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildOptionTile(
                  icon: Icons.person,
                  title: "Información personal",
                  subtitle: "Nombre, fecha de nacimiento",
                  onTap: () {},
                ),
                _buildOptionTile(
                  icon: Icons.phone,
                  title: "Información de contacto",
                  subtitle: "Email, teléfono, código postal",
                  onTap: () {},
                ),
                _buildOptionTile(
                  icon: Icons.credit_card,
                  title: "Mis métodos de pago",
                  subtitle: "Tarjetas de débito o crédito",
                  onTap: () {},
                ),
                _buildOptionTile(
                  icon: Icons.lock,
                  title: "Seguridad y privacidad",
                  subtitle: "Contraseña, comunicaciones",
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.black),
                  title: const Text("Cerrar sesión"),
                  onTap: () {
                    Provider.of<UserProvider>(context, listen: false).logout();
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle, style: GoogleFonts.roboto(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
