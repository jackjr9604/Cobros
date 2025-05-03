import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'cobros_screen.dart';
import 'clientes_screen.dart';
import 'admin/admin_home_screen.dart'; // Importación corregida
import '../utils/responsive.dart';
import 'owner/owner_home_screen.dart';
import 'collector/collector_home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _currentUserData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _userService.getCurrentUserData();
    setState(() {
      _currentUserData = userData;
      _isLoading = false;
    });
  }

  List<Widget> _getScreensBasedOnRole() {
    if (_isLoading) return [const Center(child: CircularProgressIndicator())];

    switch (_currentUserData?['role']) {
      case 'admin':
        return [
          const AdminHomeScreen(), // Ahora debería reconocer la clase
          const CobrosScreen(),
          const ClientesScreen(),
        ];
      case 'owner':
        return [
          const OwnerHomeScreen(),
          const CobrosScreen(),
          const ClientesScreen(),
        ];
      case 'collector':
        return [
          const CollectorHomeScreen(),
          const CobrosScreen(),
          const SizedBox(),
        ];
      default:
        return [const HomeScreen()];
    }
  }

  List<Widget> _getMenuItems(BuildContext context) {
    if (_isLoading) return [const SizedBox()];

    final menuItems = <Widget>[
      ListTile(
        leading: const Icon(Icons.home),
        title: const Text('Inicio'),
        selected: _selectedIndex == 0,
        selectedTileColor: Colors.blue[100],
        onTap: () => _updateIndex(0, context),
      ),
    ];

    if (_currentUserData?['role'] == 'admin') {
      menuItems.addAll([
        ListTile(
          leading: const Icon(Icons.supervised_user_circle),
          title: const Text('Usuarios'),
          selected: _selectedIndex == 1,
          selectedTileColor: Colors.blue[100],
          onTap: () => _updateIndex(1, context),
        ),
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('Oficinas'),
          selected: _selectedIndex == 2,
          selectedTileColor: Colors.blue[100],
          onTap: () => _updateIndex(2, context),
        ),
      ]);
    } else if (_currentUserData?['role'] == 'owner') {
      menuItems.add(
        ListTile(
          leading: const Icon(Icons.group_add),
          title: const Text('Registrar Cobradores'),
          selected: _selectedIndex == 1,
          selectedTileColor: Colors.blue[100],
          onTap: () => _updateIndex(1, context),
        ),
      );
    }

    menuItems.addAll([
      ListTile(
        leading: const Icon(Icons.payment),
        title: const Text('Cobros'),
        selected: _selectedIndex == 3,
        selectedTileColor: Colors.blue[100],
        onTap: () => _updateIndex(3, context),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Cerrar Sesión'),
        onTap: () async {
          await _authService.signOut();
          if (Responsive.isMobile(context)) Navigator.pop(context);
        },
      ),
    ]);

    return menuItems;
  }

  void _updateIndex(int index, BuildContext context) {
    setState(() => _selectedIndex = index);
    if (Responsive.isMobile(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final screens = _getScreensBasedOnRole();

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        toolbarHeight: isMobile ? 56 : 64,
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: isMobile,
        actions: _buildAppBarActions(),
      ),
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Row(
        children: [
          if (!isMobile) _buildDesktopMenu(context),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    if (_isLoading) return const Text('Cargando...');

    String roleName;
    switch (_currentUserData?['role']) {
      case 'admin':
        roleName = 'Administrador';
        break;
      case 'owner':
        roleName = 'Dueño de Oficina';
        break;
      case 'collector':
        roleName = 'Cobrador';
        break;
      default:
        roleName = 'Usuario';
    }

    return Text('CLIQ - $roleName');
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (!_isLoading && _currentUserData != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              _currentUserData?['email'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUserData),
    ];
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: _getMenuItems(context),
      ),
    );
  }

  Widget _buildDesktopMenu(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.blue[50],
      child: Column(
        children: [
          Container(
            height: 150,
            color: Colors.blue,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        _currentUserData?['photoUrl'] != null
                            ? NetworkImage(_currentUserData!['photoUrl'])
                            : null,
                    child:
                        _currentUserData?['photoUrl'] == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentUserData?['displayName'] ?? 'Usuario',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: ListView(children: _getMenuItems(context))),
        ],
      ),
    );
  }
}
