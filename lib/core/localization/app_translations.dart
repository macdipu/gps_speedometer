import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': {
          'settings': 'Settings',
          'language': 'Language',
          'speed_unit': 'Speed Unit',
          'theme': 'Dark Theme',
          'trips': 'Trips',
          'speedometer': 'Speedometer',
          'start_trip': 'Start Trip',
          'stop_trip': 'Stop Trip',
          'current_speed': 'Current Speed',
          'max_speed': 'Max Speed',
          'avg_speed': 'Avg',
          'distance': 'Distance',
          'duration': 'Duration',
          'trip_details': 'Trip Details',
          'date': 'Date',
          'no_trips': 'No trips recorded yet.',
          'hud_mode': 'HUD Mode',
          'speed_limit_alert': 'Speed Limit Alert',
          'speed_limit': 'Speed Limit',
        },
        'es': {
          'settings': 'Ajustes',
          'language': 'Idioma',
          'speed_unit': 'Unidad de Velocidad',
          'theme': 'Tema Oscuro',
          'trips': 'Viajes',
          'speedometer': 'Velocímetro',
          'start_trip': 'Iniciar Viaje',
          'stop_trip': 'Detener Viaje',
          'current_speed': 'Velocidad',
          'max_speed': 'Máx',
          'avg_speed': 'Prom.',
          'distance': 'Distancia',
          'duration': 'Duración',
          'trip_details': 'Detalles del Viaje',
          'date': 'Fecha',
          'no_trips': 'Aún no hay viajes registrados.',
          'hud_mode': 'Modo HUD',
          'speed_limit_alert': 'Alerta de Límite de Velocidad',
          'speed_limit': 'Límite de Velocidad',
        },
        // We can add the other 28 languages later or fallback to English automatically via GetX
      };
}
