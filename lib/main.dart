/// main.dart — App entry point
/// Sets up GetMaterialApp with:
///   - Dark/Light theming
///   - GetX routing
///   - Flutter localizations (30+ languages)
///   - Root dependency binding

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_pages.dart';
import 'core/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait by default (HUD mode overrides temporarily)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar style for dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const GpsSpeedometerApp());
}

class GpsSpeedometerApp extends StatelessWidget {
  const GpsSpeedometerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GPS Speedometer',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Localization — 30+ languages
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('it'),
        Locale('pt'),
        Locale('ru'),
        Locale('zh'),
        Locale('ja'),
        Locale('ko'),
        Locale('ar'),
        Locale('hi'),
        Locale('bn'),
        Locale('tr'),
        Locale('nl'),
        Locale('pl'),
        Locale('sv'),
        Locale('da'),
        Locale('fi'),
        Locale('nb'),
        Locale('cs'),
        Locale('sk'),
        Locale('hu'),
        Locale('ro'),
        Locale('bg'),
        Locale('uk'),
        Locale('id'),
        Locale('ms'),
        Locale('vi'),
        Locale('th'),
      ],

      // GetX Routing
      initialRoute: Routes.home,
      getPages: AppPages.pages,
      initialBinding: AppBinding(),

      // Default transition
      defaultTransition: Transition.cupertino,
    );
  }
}
