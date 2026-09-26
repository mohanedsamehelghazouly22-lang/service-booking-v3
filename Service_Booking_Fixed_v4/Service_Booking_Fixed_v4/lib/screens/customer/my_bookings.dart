import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    required this.repository,
  });

  final AppRepository repository;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<BookingItem> _items = <BookingItem>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.repository.myBookings();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Text(
            'My Bookings',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _messageCard(_error!)
          else if (_items.isEmpty)
            _messageCard('Your bookings will appear here.')
          else
            ..._items.map(_bookingCard),
        ],
      ),
    );
  }

  Widget _bookingCard(BookingItem booking) {
    return Card(
      color: AppColors.ink,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          booking.serviceName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${booking.locationName}\n${booking.date} • ${booking.time}',
        ),
        isThreeLine: true,
        trailing: Text(
          booking.status,
          style: const TextStyle(
            color: AppColors.orange,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _messageCard(String message) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(message),
    );
  }
}
