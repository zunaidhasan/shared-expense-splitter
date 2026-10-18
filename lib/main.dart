import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const SharedExpenseApp());
}

class SharedExpenseApp extends StatelessWidget {
  const SharedExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apartment Expenses',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF58D9C0),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF5ADBC1),
          secondary: const Color(0xFF00B99D),
          surface: const Color(0xFF162137),
          error: const Color(0xFFFF718A),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1223),
          foregroundColor: Color(0xFFE6ECFF),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF162137),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F192C),
          labelStyle: const TextStyle(color: Color(0xFFADB8D0)),
          hintStyle: const TextStyle(color: Color(0xFF7987A3)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF26334A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF5ADBC1), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1223),
        dividerColor: const Color(0xFF26334A),
      ),
      home: const HomeScreen(),
    );
  }
}
