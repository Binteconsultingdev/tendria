import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Filtros de la pantalla Descubrir. Se guardan en el teléfono para conservarlos entre sesiones.
class DiscoverFilters {
  static const int ageFloor = 18;
  static const int ageCeil = 80;
  static const double distanceCeil = 200;

  final int ageMin;
  final int ageMax;

  /// null = todos. Valores del API: Mujer | Hombre | No_binario
  final String? gender;

  /// null = sin límite
  final double? distanceKm;
  final bool onlyVerified;
  final bool onlyOnline;
  final Set<int> interests;

  const DiscoverFilters({
    this.ageMin = ageFloor,
    this.ageMax = ageCeil,
    this.gender,
    this.distanceKm,
    this.onlyVerified = false,
    this.onlyOnline = false,
    this.interests = const {},
  });

  bool get isActive =>
      ageMin > ageFloor ||
      ageMax < ageCeil ||
      gender != null ||
      distanceKm != null ||
      onlyVerified ||
      onlyOnline ||
      interests.isNotEmpty;

  /// Cuántos filtros están aplicados (para el globito del botón).
  int get activeCount =>
      ((ageMin > ageFloor || ageMax < ageCeil) ? 1 : 0) +
      (gender != null ? 1 : 0) +
      (distanceKm != null ? 1 : 0) +
      (onlyVerified ? 1 : 0) +
      (onlyOnline ? 1 : 0) +
      (interests.isNotEmpty ? 1 : 0);

  DiscoverFilters copyWith({
    int? ageMin,
    int? ageMax,
    String? gender,
    bool clearGender = false,
    double? distanceKm,
    bool clearDistance = false,
    bool? onlyVerified,
    bool? onlyOnline,
    Set<int>? interests,
  }) =>
      DiscoverFilters(
        ageMin: ageMin ?? this.ageMin,
        ageMax: ageMax ?? this.ageMax,
        gender: clearGender ? null : (gender ?? this.gender),
        distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
        onlyVerified: onlyVerified ?? this.onlyVerified,
        onlyOnline: onlyOnline ?? this.onlyOnline,
        interests: interests ?? this.interests,
      );

  Map<String, String> toQuery() => {
        if (ageMin > ageFloor) 'edadMin': '$ageMin',
        if (ageMax < ageCeil) 'edadMax': '$ageMax',
        if (gender != null) 'genero': gender!,
        if (distanceKm != null) 'distanciaKm': distanceKm!.round().toString(),
        if (onlyVerified) 'soloVerificados': 'true',
        if (onlyOnline) 'soloEnLinea': 'true',
        if (interests.isNotEmpty) 'intereses': interests.join(','),
      };

  Map<String, dynamic> toJson() => {
        'ageMin': ageMin,
        'ageMax': ageMax,
        'gender': gender,
        'distanceKm': distanceKm,
        'onlyVerified': onlyVerified,
        'onlyOnline': onlyOnline,
        'interests': interests.toList(),
      };

  factory DiscoverFilters.fromJson(Map<String, dynamic> j) => DiscoverFilters(
        ageMin: j['ageMin'] ?? ageFloor,
        ageMax: j['ageMax'] ?? ageCeil,
        gender: j['gender'],
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        onlyVerified: j['onlyVerified'] ?? false,
        onlyOnline: j['onlyOnline'] ?? false,
        interests: ((j['interests'] as List?) ?? const []).map((e) => e as int).toSet(),
      );
}

/// Filtros vigentes de Descubrir: la barra y la pantalla los comparten y se enteran de los cambios.
class DiscoverState {
  DiscoverState._();
  static final DiscoverState instance = DiscoverState._();

  static const _key = 'discover_filters_v1';

  final ValueNotifier<DiscoverFilters> filters = ValueNotifier(const DiscoverFilters());
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) filters.value = DiscoverFilters.fromJson(jsonDecode(raw));
    } catch (_) {}
  }

  Future<void> update(DiscoverFilters value) async {
    filters.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(value.toJson()));
    } catch (_) {}
  }
}
