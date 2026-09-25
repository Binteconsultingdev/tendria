class UsuarioChatEntity {
  final int id;
  final String nombre;
  final String? fotoUrl;
  final bool? isActive;
  final DateTime? lastSeen;

  UsuarioChatEntity({
    required this.id,
    required this.nombre,
    this.fotoUrl,
    this.isActive,
    this.lastSeen,
  });
}
