import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';

class PlanCategory {
  final String code;
  final IconData icon;
  final List<Color> colors;

  const PlanCategory(this.code, this.icon, this.colors);

  static const List<PlanCategory> all = [
    PlanCategory('salidas', LucideIcons.partyPopper, [Color(0xFFFF7A93), Color(0xFFB83A5E)]),
    PlanCategory('cine', LucideIcons.clapperboard, [Color(0xFF7C6CF2), Color(0xFF3B2FA0)]),
    PlanCategory('senderismo', LucideIcons.mountain, [Color(0xFF5FCB8A), Color(0xFF1F7A4D)]),
    PlanCategory('viajes', LucideIcons.plane, [Color(0xFF5BB8FF), Color(0xFF2456C7)]),
    PlanCategory('deportes', LucideIcons.dumbbell, [Color(0xFFFFA24C), Color(0xFFD4501B)]),
    PlanCategory('gaming', LucideIcons.gamepad2, [Color(0xFF9B5DE5), Color(0xFF4B1D8F)]),
    PlanCategory('restaurantes', LucideIcons.utensils, [Color(0xFFFFC24B), Color(0xFFC77A00)]),
    PlanCategory('conciertos', LucideIcons.music, [Color(0xFFFF5FA2), Color(0xFF8E1A66)]),
    PlanCategory('reuniones', LucideIcons.users, [Color(0xFF4FD1C5), Color(0xFF167A78)]),
    PlanCategory('social', LucideIcons.martini, [Color(0xFFF08A5D), Color(0xFF9E3A2A)]),
    PlanCategory('otro', LucideIcons.sparkles, [Color(0xFF9AA5B1), Color(0xFF4A5560)]),
  ];

  static PlanCategory of(String code) => all.firstWhere((c) => c.code == code, orElse: () => all.last);
}

class PlanEntity {
  final int id;
  final AuthorEntity creator;
  final String title;
  final String? description;
  final String? imageUrl;
  final String category;
  final DateTime startsAt;
  final String placeName;
  final double? lat;
  final double? lng;
  final String? city;
  final int? capacity;
  final int confirmed;
  final String privacy; // publico | aprobacion
  final bool cancelled;
  final String? myState; // confirmado | pendiente | rechazado
  final bool isMine;
  final double? distanceKm;
  final List<AuthorEntity> participants;
  final List<AuthorEntity> pending;

  PlanEntity({
    required this.id,
    required this.creator,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.startsAt,
    required this.placeName,
    required this.lat,
    required this.lng,
    required this.city,
    required this.capacity,
    required this.confirmed,
    required this.privacy,
    required this.cancelled,
    required this.myState,
    required this.isMine,
    required this.distanceKm,
    required this.participants,
    required this.pending,
  });

  bool get requiresApproval => privacy == 'aprobacion';
  bool get isFull => capacity != null && confirmed >= capacity!;
  bool get isPast => startsAt.isBefore(DateTime.now());
  bool get joined => myState == 'confirmado';
  bool get requested => myState == 'pendiente';

  factory PlanEntity.fromJson(Map<String, dynamic> json) {
    List<AuthorEntity> people(dynamic list) =>
        (list as List<dynamic>? ?? []).map((e) => AuthorEntity.fromJson(e)).toList();

    final raw = json['fechaInicio'] as String;
    final hasZone = raw.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(raw);

    return PlanEntity(
      id: json['id'],
      creator: AuthorEntity.fromJson(json['creador']),
      title: json['titulo'] ?? '',
      description: json['descripcion'],
      imageUrl: json['imagenUrl'],
      category: json['categoria'] ?? 'otro',
      startsAt: DateTime.parse(hasZone ? raw : '${raw}Z').toLocal(),
      placeName: json['ubicacionNombre'] ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      city: json['ciudad'],
      capacity: json['cupo'],
      confirmed: json['confirmados'] ?? 0,
      privacy: json['privacidad'] ?? 'publico',
      cancelled: json['cancelado'] ?? false,
      myState: json['miEstado'],
      isMine: json['esMio'] ?? false,
      distanceKm: (json['distanciaKm'] as num?)?.toDouble(),
      participants: people(json['participantes']),
      pending: people(json['pendientes']),
    );
  }
}
