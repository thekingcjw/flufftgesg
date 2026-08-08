import 'package:flutter/material.dart';

import 'screens/first_run_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';
import 'services/completion_repository.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'theme/skinflow_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = PreferencesService.instance;
  final showFirstRun = await preferences.shouldShowFirstRun();
  await CompletionRepository.instance.initialize();
  await NotificationService.instance.initialize();
  final settings = await preferences.loadSettings();
  await NotificationService.instance.reschedule(settings);

  runApp(SkinFlowApp(showFirstRun: showFirstRun));
}

class SkinFlowApp extends StatefulWidget {
  const SkinFlowApp({super.key, required this.showFirstRun});

  final bool showFirstRun;

  @override
  State<SkinFlowApp> createState() => _SkinFlowAppState();
}

class _SkinFlowAppState extends State<SkinFlowApp> {
  late bool _showFirstRun;

  @override
  void initState() {
    super.initState();
    _showFirstRun = widget.showFirstRun;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinFlow',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: buildSkinFlowTheme(),
      home: _showFirstRun
          ? FirstRunScreen(
              onFinished: () => setState(() => _showFirstRun = false),
            )
          : const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  var _index = 0;

  static const _screens = <Widget>[
    TodayScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.auto_awesome_outlined),
        titleSpacing: 0,
        title: const Text(
          'SkinFlow',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            selectedIcon: Icon(Icons.stars),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
