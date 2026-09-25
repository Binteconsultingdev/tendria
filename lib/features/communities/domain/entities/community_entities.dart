import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';

class CommunityCategory {
  final String code;
  final IconData icon;
  final List<Color> colors;

  const CommunityCategory(this.code, this.icon, this.colors);

  static const List<CommunityCategory> all = [
    CommunityCategory('gaming', LucideIcons.gamepad2, [Color(0xFF9B5DE5), Color(0xFF4B1D8F)]),
    CommunityCategory('fitness', LucideIcons.dumbbell, [Color(0xFFFFA24C), Color(0xFFD4501B)]),
    CommunityCategory('viajes', LucideIcons.plane, [Color(0xFF5BB8FF), Color(0xFF2456C7)]),
    CommunityCategory('musica', LucideIcons.music, [Color(0xFFFF5FA2), Color(0xFF8E1A66)]),
    CommunityCategory('deportes', LucideIcons.trophy, [Color(0xFF5FCB8A), Color(0xFF1F7A4D)]),
    CommunityCategory('fotografia', LucideIcons.camera, [Color(0xFF7C6CF2), Color(0xFF3B2FA0)]),
    CommunityCategory('cocina', LucideIcons.chefHat, [Color(0xFFFFC24B), Color(0xFFC77A00)]),
    CommunityCategory('arte', LucideIcons.palette, [Color(0xFFF08A5D), Color(0xFF9E3A2A)]),
    CommunityCategory('tecnologia', LucideIcons.cpu, [Color(0xFF4FD1C5), Color(0xFF167A78)]),
    CommunityCategory('local', LucideIcons.mapPin, [Color(0xFFFF7A93), Color(0xFFB83A5E)]),
    CommunityCategory('otro', LucideIcons.sparkles, [Color(0xFF9AA5B1), Color(0xFF4A5560)]),
  ];

  static CommunityCategory of(String code) => all.firstWhere((c) => c.code == code, orElse: () => all.last);
}

class CommunityEntity {
  final int id;
  final String name;
  final String? description;
  final String category;
  final String privacy; // publica | privada
  final String? city;
  final String? imageUrl;
  final String? coverUrl;
  final int members;
  final AuthorEntity creator;
  final String? myState; // activo | pendiente
  final String? myRole; // admin | moderador | miembro
  final bool isCreator;
  final bool canViewContent;
  final List<AuthorEntity> latestMembers;
  final int? pendingRequests;

  CommunityEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.privacy,
    required this.city,
    required this.imageUrl,
    required this.coverUrl,
    required this.members,
    required this.creator,
    required this.myState,
    required this.myRole,
    required this.isCreator,
    required this.canViewContent,
    required this.latestMembers,
    required this.pendingRequests,
  });

  bool get isPrivate => privacy == 'privada';
  bool get isMember => myState == 'activo';
  bool get isPending => myState == 'pendiente';
  bool get isAdmin => myRole == 'admin';
  bool get canModerate => myRole == 'admin' || myRole == 'moderador';

  CommunityBrief get brief => CommunityBrief(id: id, name: name, imageUrl: imageUrl);

  factory CommunityEntity.fromJson(Map<String, dynamic> json) => CommunityEntity(
        id: json['id'],
        name: json['nombre'] ?? '',
        description: json['descripcion'],
        category: json['categoria'] ?? 'otro',
        privacy: json['privacidad'] ?? 'publica',
        city: json['ciudad'],
        imageUrl: json['imagenUrl'],
        coverUrl: json['portadaUrl'],
        members: json['miembros'] ?? 0,
        creator: AuthorEntity.fromJson(json['creador']),
        myState: json['miEstado'],
        myRole: json['miRol'],
        isCreator: json['esCreador'] ?? false,
        canViewContent: json['puedeVerContenido'] ?? true,
        latestMembers: (json['ultimosMiembros'] as List<dynamic>? ?? []).map((e) => AuthorEntity.fromJson(e)).toList(),
        pendingRequests: json['solicitudesPendientes'],
      );
}

class MemberEntity {
  final AuthorEntity user;
  final String role;
  final String state;

  MemberEntity({required this.user, required this.role, required this.state});

  factory MemberEntity.fromJson(Map<String, dynamic> json) => MemberEntity(
        user: AuthorEntity.fromJson(json['usuario']),
        role: json['rol'] ?? 'miembro',
        state: json['estado'] ?? 'activo',
      );
}
