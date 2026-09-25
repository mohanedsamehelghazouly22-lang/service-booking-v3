import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../repositories/app_repository.dart';

class BookingFlow extends StatefulWidget {
  const BookingFlow({
    super.key,
    required this.repository,
    required this.service,
  });

  final AppRepository repository;
  final ServiceItem service;

  @override
  State<BookingFlow> createState() => _BookingFlowState();
}

class _BookingFlowState extends State<BookingFlow> {
  int _step = 0;
  List<LocationItem> _locations = <LocationItem>[];
  List<SlotItem> _slots = <SlotItem>[];
  LocationItem? _selectedLocation;
  SlotItem? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.repository.locations(widget.service.id);
      if (!mounted) return;
      setState(() => _locations = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadSlots() async {
    final selectedLocation = _selectedLocation;
    if (selectedLocation == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _selectedSlot = null;
    });

    try {
      final result = await widget.repository.slots(
        serviceId: widget.service.id,
        locationId: selectedLocation.id,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      if (!mounted) return;
      setState(() => _slots = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createBooking() async {
    final selectedLocation = _selectedLocation;
    final selectedSlot = _selectedSlot;
    if (selectedLocation == null || selectedSlot == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.repository.createBooking(<String, dynamic>{
        'service_id': widget.service.id,
        'location_id': selectedLocation.id,
        'slot_id': selectedSlot.id,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      });

      if (!mounted) return;

      final booking = result['booking'];
      final status = booking is Map
          ? booking['status']?.toString() ?? 'Pending'
          : 'Pending';

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Booking created'),
          content: Text('Your booking status is $status.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _continue() {
    if (_step == 0) {
      if (_selectedLocation == null) {
        setState(() => _error = 'Please choose a location.');
        return;
      }
      setState(() {
        _error = null;
        _step = 1;
      });
      return;
    }

    if (_step == 1) {
      setState(() {
        _error = null;
        _step = 2;
      });
      _loadSlots();
      return;
    }

    if (_selectedSlot == null) {
      setState(() => _error = 'Please choose an available time slot.');
      return;
    }

    _createBooking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.peach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(
          widget.service.name,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              backgroundColor: Colors.black12,
              color: AppColors.orange,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _step == 0
                  ? _locationStep()
                  : _step == 1
                      ? _dateStep()
                      : _slotStep(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _continue,
                child: Text(_step == 2 ? 'Confirm booking' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationStep() {
    return ListView(
      children: <Widget>[
        const Text(
          'Choose location',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_locations.isEmpty)
          const Text(
            'No locations are available for this service.',
            style: TextStyle(color: AppColors.ink),
          )
        else
          ..._locations.map(
            (location) => Card(
              color: AppColors.ink,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () {
                  setState(() {
                    _selectedLocation = location;
                    _selectedSlot = null;
                    _error = null;
                  });
                },
                leading: Icon(
                  _selectedLocation?.id == location.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.orange,
                ),
                title: Text(
                  location.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${location.city}, ${location.governorate}',
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dateStep() {
    return ListView(
      children: <Widget>[
        const Text(
          'Pick a date',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 180)),
          onDateChanged: (value) {
            setState(() {
              _selectedDate = value;
              _selectedSlot = null;
              _error = null;
            });
          },
        ),
      ],
    );
  }

  Widget _slotStep() {
    return ListView(
      children: <Widget>[
        Text(
          DateFormat('EEEE, d MMMM').format(_selectedDate),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_slots.isEmpty)
          const Text(
            'No available slots for this date.',
            style: TextStyle(color: AppColors.ink),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _slots.map((slot) {
              return ChoiceChip(
                label: Text(slot.startsAt),
                selected: _selectedSlot?.id == slot.id,
                onSelected: slot.available
                    ? (_) => setState(() {
                          _selectedSlot = slot;
                          _error = null;
                        })
                    : null,
              );
            }).toList(),
          ),
      ],
    );
  }
}
