import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  SupabaseClient get client => Supabase.instance.client;

  Future<void> saveToken(String token) async {}

  Future<void> clearToken() async {
    await client.auth.signOut();
  }
}
