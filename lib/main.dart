import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:schoolnet/screens/loginScreens/startupScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchoolNet',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: const StartupScreen(),
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        iconTheme: const IconThemeData(color: Colors.black),
        useMaterial3: true,
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
            fontSizeFactor: 0.8,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal),
          ),
          floatingLabelStyle: TextStyle(color: Colors.teal),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          background: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
      ),
    );
  }
}
