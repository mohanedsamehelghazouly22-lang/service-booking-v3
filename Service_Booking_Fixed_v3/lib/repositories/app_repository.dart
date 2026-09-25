import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class AppRepository {
  AppRepository(this.client);
  final SupabaseClient client;

  User? get currentUser => client.auth.currentUser;

  Future<void> sendOtp(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyOtp(String phone, String code) {
    return client.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);
  }

  Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.servicebooking://login-callback/',
    );
  }

  Future<Map<String, dynamic>> profile() async {
    final user = currentUser;
    if (user == null) throw const AuthException('You are not signed in.');

    final row = await client.from('users').select().eq('id', user.id).maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);

    final inserted = await client.from('users').insert({
      'id': user.id,
      'email': user.email,
      'phone': user.phone,
      'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '',
      'role': 'customer',
    }).select().single();

    return Map<String, dynamic>.from(inserted);
  }

  Future<List<ServiceItem>> services() async {
    final rows = await client
        .from('services')
        .select('id,name,description,image_url')
        .eq('enabled', true)
        .order('name');
    return rows.map<ServiceItem>((e) => ServiceItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<LocationItem>> locations(String serviceId) async {
    final links = await client
        .from('service_locations')
        .select('location_id')
        .eq('service_id', serviceId);

    final ids = links.map((e) => e['location_id'].toString()).toList();
    if (ids.isEmpty) return [];

    final rows = await client
        .from('locations')
        .select('id,name,city,governorate')
        .inFilter('id', ids)
        .eq('enabled', true)
        .order('name');

    return rows.map<LocationItem>((e) => LocationItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<SlotItem>> slots({
    required String serviceId,
    required String locationId,
    required String date,
  }) async {
    final dayStart = DateTime.parse('${date}T00:00:00Z');
    final dayEnd = dayStart.add(const Duration(days: 1));

    final slotRows = await client
        .from('slots')
        .select('id,starts_at,ends_at,capacity')
        .eq('service_id', serviceId)
        .eq('location_id', locationId)
        .eq('enabled', true)
        .gte('starts_at', dayStart.toIso8601String())
        .lt('starts_at', dayEnd.toIso8601String())
        .order('starts_at');

    if (slotRows.isEmpty) return [];

    final slotIds = slotRows.map((e) => e['id'].toString()).toList();
    final bookingRows = await client
        .from('bookings')
        .select('slot_id')
        .inFilter('slot_id', slotIds)
        .inFilter('status', ['pending', 'confirmed']);

    final counts = <String, int>{};
    for (final row in bookingRows) {
      final id = row['slot_id'].toString();
      counts[id] = (counts[id] ?? 0) + 1;
    }

    return slotRows.map<SlotItem>((e) {
      final id = e['id'].toString();
      final capacity = (e['capacity'] as num?)?.toInt() ?? 1;
      final available = (counts[id] ?? 0) < capacity;
      return SlotItem.fromJson({
        'id': id,
        'starts_at': e['starts_at'],
        'ends_at': e['ends_at'],
        'available': available,
      });
    }).toList();
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> body) async {
    final user = currentUser;
    if (user == null) throw const AuthException('Please sign in before booking.');

    final result = await client.rpc('create_booking', params: {
      'p_customer_id': user.id,
      'p_service_id': body['service_id'],
      'p_location_id': body['location_id'],
      'p_slot_id': body['slot_id'],
    });

    if (result is Map<String, dynamic>) return result;
    return {'booking': result};
  }

  Future<List<BookingItem>> myBookings() async {
    final user = currentUser;
    if (user == null) return [];

    final rows = await client
        .from('bookings')
        .select('id,service_id,location_id,slot_id,status,created_at,slots(starts_at,ends_at),services(name),locations(name)')
        .eq('customer_id', user.id)
        .order('created_at', ascending: false);

    return rows.map<BookingItem>((row) {
      final r = Map<String, dynamic>.from(row);
      final slot = r['slots'] is Map ? Map<String, dynamic>.from(r['slots']) : <String, dynamic>{};
      final service = r['services'] is Map ? Map<String, dynamic>.from(r['services']) : <String, dynamic>{};
      final location = r['locations'] is Map ? Map<String, dynamic>.from(r['locations']) : <String, dynamic>{};
      final start = DateTime.tryParse(slot['starts_at']?.toString() ?? '');
      return BookingItem(
        id: r['id'].toString(),
        serviceName: service['name']?.toString() ?? 'Service',
        locationName: location['name']?.toString() ?? 'Location',
        date: start == null ? '' : '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        time: start == null ? '' : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
        status: r['status']?.toString() ?? 'pending',
      );
    }).toList();
  }

  Future<void> cancelBooking(String id) async {
    await client.rpc('cancel_booking', params: {'p_booking_id': id});
  }
}
