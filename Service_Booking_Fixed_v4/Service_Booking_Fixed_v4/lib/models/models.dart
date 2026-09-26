class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Service',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}

class LocationItem {
  const LocationItem({
    required this.id,
    required this.name,
    required this.city,
    required this.governorate,
  });

  final String id;
  final String name;
  final String city;
  final String governorate;

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Location',
      city: json['city']?.toString() ?? '',
      governorate: json['governorate']?.toString() ?? '',
    );
  }
}

class SlotItem {
  const SlotItem({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.available,
  });

  final String id;
  final String startsAt;
  final String endsAt;
  final bool available;

  factory SlotItem.fromJson(Map<String, dynamic> json) {
    return SlotItem(
      id: json['id']?.toString() ?? '',
      startsAt: json['starts_at']?.toString() ?? '',
      endsAt: json['ends_at']?.toString() ?? '',
      available: json['available'] == true,
    );
  }
}

class BookingItem {
  const BookingItem({
    required this.id,
    required this.serviceName,
    required this.locationName,
    required this.date,
    required this.time,
    required this.status,
  });

  final String id;
  final String serviceName;
  final String locationName;
  final String date;
  final String time;
  final String status;
}
