import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
       url: 'https://ioniwnodlpekyxtrzayp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlvbml3bm9kbHBla3l4dHJ6YXlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc4MjU1NTgsImV4cCI6MjA2MzQwMTU1OH0.jcq0AFNdGi1rbVi5TlTq4sre8xC_j6kiDWFlj9eTN3g',
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 20, // Reduced from 40 to avoid rate limits
      timeout: Duration(seconds: 30), // Increase timeout
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Tailor Management',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final session = snapshot.data!.session;
                if (session != null) {
                  return const HomeScreen();
                }
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}