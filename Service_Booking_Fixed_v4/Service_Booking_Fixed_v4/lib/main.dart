import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'repositories/app_repository.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/provider/provider_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (url.isEmpty || publishableKey.isEmpty) {
    runApp(const _ConfigurationErrorApp());
    return;
  }

  await Supabase.initialize(
    url: url,
    publishableKey: publishableKey,
  );

  runApp(const ServiceBookingApp());
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        backgroundColor: AppColors.peach,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: AppColors.ink,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Supabase configuration is missing.\n\nBuild with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceBookingApp extends StatelessWidget {
  const ServiceBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final api = ApiClient();
    final repository = AppRepository(client);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Service Booking',
      theme: buildTheme(),
      home: _SessionGate(api: api, repository: repository),
      routes: {
        '/home': (_) => HomeScreen(api: api, repository: repository),
        '/provider': (_) => const ProviderDashboard(),
        '/admin': (_) => const AdminDashboard(),
      },
    );
  }
}

class _SessionGate extends StatelessWidget {
  const _SessionGate({required this.api, required this.repository});

  final ApiClient api;
  final AppRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return LoginScreen(api: api, repository: repository);
        }
        return HomeScreen(api: api, repository: repository);
      },
    );
  }
}
