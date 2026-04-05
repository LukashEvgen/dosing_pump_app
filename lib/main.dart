import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/pump_provider.dart';
import 'providers/osmosis_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/schedules_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/osmosis_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DosingPumpApp());
}

class DosingPumpApp extends StatelessWidget {
  const DosingPumpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PumpProvider()),
        ChangeNotifierProvider(create: (_) => OsmosisProvider()),
      ],
      child: MaterialApp(
        title: 'Dosing Pump',
        theme: AppTheme.dark,
        home: const MainShell(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigate: _navigateTo),
      const HomeScreen(),
      const SchedulesScreen(),
      const OsmosisScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.primaryDark.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Огляд',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.science_outlined),
              activeIcon: Icon(Icons.science),
              label: 'Помпа',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined),
              activeIcon: Icon(Icons.schedule),
              label: 'Розклад',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_outlined),
              activeIcon: Icon(Icons.water_drop),
              label: 'Осмос',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Налаштування',
            ),
          ],
        ),
      ),
    );
  }
}
