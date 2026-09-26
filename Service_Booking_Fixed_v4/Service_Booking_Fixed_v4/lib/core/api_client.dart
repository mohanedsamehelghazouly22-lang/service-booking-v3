import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  Future<void> signOut() => client.auth.signOut();
}
