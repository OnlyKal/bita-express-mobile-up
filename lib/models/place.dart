class Place {
  final String placeId;
  final double latitude;
  final double longitude;
  final String displayName;
  final String type;

  Place({
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.type,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      placeId: json['place_id']?.toString() ?? '',
      latitude: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      displayName: json['display_name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'display_name': displayName,
      'type': type,
    };
  }

  @override
  String toString() {
    return 'Place(placeId: $placeId, displayName: $displayName, lat: $latitude, lon: $longitude)';
  }
}
