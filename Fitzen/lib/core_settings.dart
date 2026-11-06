import 'dart:ui';
import 'package:flutter/material.dart';

// 1. GLOBAL STATE NOTIFIERS
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<String> languageNotifier = ValueNotifier('English');

// 2. TRANSLATION DICTIONARY
final Map<String, Map<String, String>> _localizedStrings = {
  'English': {},
  'Spanish': {
    'Settings': 'Ajustes',
    'APP PREFERENCES': 'PREFERENCIAS DE LA APP',
    'Dark Theme': 'Tema Oscuro',
    'Enable dark mode interface': 'Activar interfaz en modo oscuro',
    'Language': 'Idioma',
    'UNITS & MEASUREMENTS': 'UNIDADES Y MEDIDAS',
    'Weight Unit': 'Unidad de Peso',
    'Water Volume': 'Volumen de Agua',
    'DATA & INTEGRATIONS': 'DATOS E INTEGRACIONES',
    'Sync with Google Fit': 'Sincronizar con Google Fit',
    'Bi-directional daily metrics sync': 'Sincronización diaria bidireccional',
    'Export My Data': 'Exportar Mis Datos',
    'Download complete nutrition & metrics archive': 'Descargar archivo completo de nutrición',
    'SUPPORT & ABOUT': 'SOPORTE Y ACERCA DE',
    'Help Center & FAQ': 'Centro de Ayuda y FAQ',
    'Privacy Policy': 'Política de Privacidad',
    'Terms of Service': 'Términos de Servicio',
    'Select Language': 'Seleccionar Idioma',
    'Preparing data export in JSON/CSV...': 'Preparando exportación de datos...'
  },
  'French': {
    'Settings': 'Paramètres',
    'APP PREFERENCES': 'PRÉFÉRENCES DE L\'APP',
    'Dark Theme': 'Thème Sombre',
    'Enable dark mode interface': 'Activer l\'interface en mode sombre',
    'Language': 'Langue',
    'UNITS & MEASUREMENTS': 'UNITÉS ET MESURES',
    'Weight Unit': 'Unité de Poids',
    'Water Volume': 'Volume d\'Eau',
    'DATA & INTEGRATIONS': 'DONNÉES ET INTÉGRATIONS',
    'Sync with Google Fit': 'Synchroniser avec Google Fit',
    'Bi-directional daily metrics sync': 'Synchronisation quotidienne',
    'Export My Data': 'Exporter Mes Données',
    'Download complete nutrition & metrics archive': 'Télécharger les archives complètes',
    'SUPPORT & ABOUT': 'SUPPORT ET À PROPOS',
    'Help Center & FAQ': 'Centre d\'Aide et FAQ',
    'Privacy Policy': 'Politique de Confidentialité',
    'Terms of Service': 'Conditions d\'Utilisation',
    'Select Language': 'Sélectionner la Langue',
    'Preparing data export in JSON/CSV...': 'Préparation de l\'exportation...'
  }
};

String tr(String key) {
  return _localizedStrings[languageNotifier.value]?[key] ?? key;
}

// 3. DYNAMIC ULTRA-LUXE COLOR PALETTE HELPER
class AppColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : Colors.white;

  static Color cardGlass(BuildContext context) => isDark(context)
      ? const Color(0xFF1E293B).withOpacity(0.85)
      : Colors.white.withOpacity(0.88);

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static Color border(BuildContext context) => isDark(context)
      ? const Color(0xFF334155).withOpacity(0.8)
      : const Color(0xFFE2E8F0);

  static Color iconBg(BuildContext context) => isDark(context)
      ? const Color(0xFFE91E8C).withOpacity(0.18)
      : const Color(0xFFE91E8C).withOpacity(0.12);

  static const Color primaryAccent = Color(0xFFE91E8C);
  static const Color secondaryAccent = Color(0xFFFF8A3D);
}

// 4. SMART SCREEN WRAPPER WITH AURORA BACKGROUND
class FitzenScreen extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  const FitzenScreen({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, themeMode, child) {
            final isDark = AppColors.isDark(context);
            return Scaffold(
              backgroundColor: AppColors.background(context),
              appBar: appBar,
              body: Stack(
                children: [
                  // Ambient Bioluminescent Aurora background
                  Positioned(
                    top: -90,
                    right: -70,
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0x20FF8A3D) : const Color(0x30FF8A3D),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 220,
                    left: -110,
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0x20E91E8C) : const Color(0x28E91E8C),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    right: -90,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0x1800ACC1) : const Color(0x2000ACC1),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  body,
                ],
              ),
              floatingActionButton: floatingActionButton,
            );
          },
        );
      },
    );
  }
}