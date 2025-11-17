import 'package:flutter/material.dart';

class VehicleType {
  final String id;
  final String name;
  final String label; // Affichage (ex: "Moto", "Voiture confort")
  final IconData icon;
  final Color color;
  final int minCapacity;
  final String description;

  VehicleType({
    required this.id,
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
    required this.minCapacity,
    required this.description,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] ?? '',
      name: json['name'] ?? json['type_vehicule'] ?? '',
      label: json['label'] ?? json['type_vehicule'] ?? '',
      icon: _getIconForType(json['name'] ?? json['type_vehicule'] ?? ''),
      color: _getColorForType(json['name'] ?? json['type_vehicule'] ?? ''),
      minCapacity: json['min_capacity'] ?? 1,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
      'min_capacity': minCapacity,
      'description': description,
    };
  }

  static IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'moto':
      case 'motocyclette':
        return Icons.two_wheeler;
      case 'voiture':
      case 'automobile':
        return Icons.directions_car;
      case 'taxi':
        return Icons.local_taxi;
      case 'bus':
        return Icons.directions_bus;
      case 'minibus':
        return Icons.airport_shuttle;
      case 'suv':
        return Icons.directions_car;
      case 'pickup':
        return Icons.local_shipping;
      case 'camion':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  static Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'moto':
      case 'motocyclette':
        return Colors.orange;
      case 'voiture':
      case 'automobile':
        return Colors.blue;
      case 'taxi':
        return Colors.yellow[700] ?? Colors.yellow;
      case 'bus':
        return Colors.green;
      case 'minibus':
        return Colors.purple;
      case 'suv':
        return Colors.red;
      case 'pickup':
        return Colors.brown;
      case 'camion':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  String toString() => 'VehicleType(id: $id, name: $name, label: $label)';
}
