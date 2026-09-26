import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';
import 'package:tendria/features/discover/discover_filters.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';

class FeaturedProfile {
  final int id;
  final String name;
  final String? photoUrl;
  final int age;
  final String? city;
  final String? country;
  final String? bio;
  final int followers;
  final bool verified;
  final bool following;
  final bool online;
  final double? distanceKm;
  final int? compatibility;
  final int commonInterests;

  FeaturedProfile({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.age,
    required this.city,
    required this.country,
    required this.bio,
    required this.followers,
    required this.verified,
    required this.following,
    required this.online,
    required this.distanceKm,
    required this.compatibility,
    required this.commonInterests,
  });

  factory FeaturedProfile.fromJson(Map<String, dynamic> j) => FeaturedProfile(
        id: j['id'],
        name: j['nombre'] ?? '',
        photoUrl: j['fotoUrl'],
        age: j['edad'] ?? 0,
        city: j['ciudad'],
        country: j['pais'],
        bio: j['bio'],
        followers: j['seguidores'] ?? 0,
        verified: j['verificado'] ?? false,
        following: j['yoSigo'] ?? false,
        online: j['enLinea'] ?? false,
        distanceKm: (j['distanciaKm'] as num?)?.toDouble(),
        compatibility: j['compatibilidad'],
        commonInterests: j['interesesEnComun'] ?? 0,
      );
}

class InterestItem {
  final int id;
  final String name;
  InterestItem(this.id, this.name);
}

class DiscoverData {
  final String? city;
  final String? country;
  final List<FeaturedProfile> compatible;
  final List<FeaturedProfile> nearby;
  final List<FeaturedProfile> inCity;
  final List<FeaturedProfile> inCountry;
  final List<FeaturedProfile> featured;
  final List<PlanEntity> plans;
  final List<CommunityEntity> communities;

  DiscoverData({
    required this.city,
    required this.country,
    required this.compatible,
    required this.nearby,
    required this.inCity,
    required this.inCountry,
    required this.featured,
    required this.plans,
    required this.communities,
  });

  bool get noProfiles => compatible.isEmpty && nearby.isEmpty && inCity.isEmpty && inCountry.isEmpty && featured.isEmpty;
  bool get isEmpty => noProfiles && plans.isEmpty && communities.isEmpty;
}

/// Perfiles, planes y comunidades para Descubrir en una sola llamada, con filtros.
class DiscoverRepository {
  final AuthService _auth = AuthService();

  static DiscoverRepository get instance {
    if (!Get.isRegistered<DiscoverRepository>()) Get.put(DiscoverRepository(), permanent: true);
    return Get.find<DiscoverRepository>();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    if (token == null) throw Exception('Sin sesión');
    return {'Authorization': 'Bearer $token'};
  }

  List<FeaturedProfile> _profiles(dynamic list) =>
      ((list as List?) ?? const []).map((e) => FeaturedProfile.fromJson(e)).toList();

  Future<DiscoverData> load(DiscoverFilters filters) async {
    final uri = Uri.parse('${AppConstants.serverBase}/Descubrir').replace(queryParameters: filters.toQuery());
    final r = await http.get(uri, headers: await _headers());
    if (r.statusCode != 200) throw Exception('No se pudo cargar Descubrir');

    final data = jsonDecode(utf8.decode(r.bodyBytes));
    return DiscoverData(
      city: data['ciudad'],
      country: data['pais'],
      compatible: _profiles(data['compatibles']),
      nearby: _profiles(data['cercanos']),
      inCity: _profiles(data['enCiudad']),
      inCountry: _profiles(data['enPais']),
      featured: _profiles(data['perfiles']),
      plans: (data['planes'] as List).map((e) => PlanEntity.fromJson(e)).toList(),
      communities: (data['comunidades'] as List).map((e) => CommunityEntity.fromJson(e)).toList(),
    );
  }

  List<InterestItem>? _interestsCache;

  /// Catálogo de intereses para el filtro.
  Future<List<InterestItem>> interests() async {
    if (_interestsCache != null) return _interestsCache!;
    final r = await http.get(Uri.parse('${AppConstants.serverBase}/Catalogos/intereses'), headers: await _headers());
    if (r.statusCode != 200) throw Exception('No se pudieron cargar los intereses');
    final list = jsonDecode(utf8.decode(r.bodyBytes)) as List;
    return _interestsCache = list.map((e) => InterestItem(e['id'], e['nombre'] ?? '')).toList();
  }
}
