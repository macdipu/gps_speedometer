/// HomeShell — Bottom navigation shell that hosts the main feature tabs.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gps_speedometer/core/utils/app_theme.dart';
import 'package:gps_speedometer/features/speedometer/presentation/screens/speedometer_screen.dart';
import 'package:gps_speedometer/features/speedometer/presentation/controllers/speedometer_controller.dart';
import 'package:gps_speedometer/features/trip/presentation/screens/trip_recording_screen.dart';
import 'package:gps_speedometer/features/trip/presentation/screens/trip_history_screen.dart';
import 'package:gps_speedometer/features/trip/presentation/controllers/trip_controller.dart';
import 'package:gps_speedometer/features/settings/presentation/screens/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // SettingsController is already registered in main.dart — do not re-register.
    Get.put(SpeedometerController());
    Get.put(TripController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SpeedometerScreen(),
          TripRecordingScreen(),
          TripHistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.cardBorderColor, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.speed_outlined),
              selectedIcon: Icon(Icons.speed),
              label: 'Speed',
            ),
            NavigationDestination(
              icon: Icon(Icons.fiber_manual_record_outlined),
              selectedIcon: Icon(Icons.fiber_manual_record),
              label: 'Record',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history),
              label: 'Trips',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
