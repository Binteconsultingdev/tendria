import 'package:tendria/features/chat/data/presence_repository.dart';
import 'package:tendria/features/chat/domain/entities/usuario_chat_entity.dart';

class UsuarioChatModel extends UsuarioChatEntity {
  UsuarioChatModel({
    required super.id,
    required super.nombre,
    super.fotoUrl,
    super.isActive,
    super.lastSeen,
  });

  factory UsuarioChatModel.fromJson(Map<String, dynamic> json) {
    return UsuarioChatModel(
      id: json['id'],
      nombre: json['nombre'],
      fotoUrl: json['fotoUrl'],
      isActive: json['estaActivo'],
      lastSeen: parseUtcDate(json['ultimaConexion']),
    );
  }
}
