class ServiceItem {
  final String id, name, description, imageUrl;
  ServiceItem({required this.id, required this.name, required this.description, required this.imageUrl});
  factory ServiceItem.fromJson(Map<String, dynamic> j) => ServiceItem(id: j['id'], name: j['name'], description: j['description'] ?? '', imageUrl: j['image_url'] ?? '');
}

class LocationItem {
  final String id, name, city, governorate;
  LocationItem({required this.id, required this.name, required this.city, required this.governorate});
  factory LocationItem.fromJson(Map<String, dynamic> j) => LocationItem(id: j['id'], name: j['name'], city: j['city'], governorate: j['governorate']);
}

class SlotItem {
  final String id, startsAt, endsAt;
  final bool available;
  SlotItem({required this.id, required this.startsAt, required this.endsAt, required this.available});
  factory SlotItem.fromJson(Map<String, dynamic> j) => SlotItem(id: j['id'], startsAt: j['starts_at'], endsAt: j['ends_at'], available: j['available'] == true);
}

class BookingItem {
  final String id, serviceName, locationName, date, time, status;
  BookingItem({required this.id, required this.serviceName, required this.locationName, required this.date, required this.time, required this.status});
  factory BookingItem.fromJson(Map<String, dynamic> j) => BookingItem(id: j['id'], serviceName: j['service_name'], locationName: j['location_name'], date: j['date'], time: j['time'], status: j['status']);
}
