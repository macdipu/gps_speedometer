/// HomeShell — Bottom navigation shell that hosts the main feature tabs.
/// Architecture: persistent tab state using GetX IndexedStack approach.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gps_speedometer/core/utils/app_theme.dart';
import 'package:gps_speedometer/features/speedometer/presentation/screens/speedometer_screen.dart';
import 'package:gps_speedometer/features/speedometer/presentation/controllers/speedometer_controller.dart';
import 'package:gps_speedometer/features/trip/presentation/screens/trip_recording_screen.dart';
import 'package:gps_speedometer/features/trip/presentation/screens/trip_history_screen.dart';
import 'package:gps_speedometer/features/trip/presentation/controllers/trip_controller.dart';
import 'package:gps_speedometer/features/settings/presentation/screens/settings_screen.dart';
import 'package:gps_speedometer/features/settings/presentation/controllers/settings_controller.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  // Initialize controllers for each tab
  @override
  void initState() {
    super.initState();
    Get.put(SpeedometerController());
    Get.put(TripController());
    Get.put(SettingsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
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
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.bgCardLight, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.bgCard,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.speed, color: AppColors.textSecondary),
              selectedIcon:
                  Icon(Icons.speed, color: AppColors.primary),
              label: 'Speed',
            ),
            NavigationDestination(
              icon: Icon(Icons.fiber_manual_record_outlined,
                  color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.fiber_manual_record,
                  color: AppColors.error),
              label: 'Record',
            ),
            NavigationDestination(
              icon: Icon(Icons.history, color: AppColors.textSecondary),
              selectedIcon:
                  Icon(Icons.history, color: AppColors.primary),
              label: 'Trips',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined,
                  color: AppColors.textSecondary),
              selectedIcon:
                  Icon(Icons.settings, color: AppColors.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
