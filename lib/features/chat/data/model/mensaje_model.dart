import 'package:tendria/features/chat/domain/entities/mensaje_entity.dart';

class MensajeModel extends MensajeEntity {
  MensajeModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    super.senderNombre,
    super.senderFoto,
    super.mensaje,
    required super.enviadoEn,
    required super.esPropio,
    super.leidoEn,
    super.giftCode,
    super.giftName,
  });

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderNombre: json['senderNombre'],
      senderFoto: json['senderFoto'],
      mensaje: json['mensaje'],
      enviadoEn: DateTime.parse(json['enviadoEn']),
      esPropio: json['esPropio'],
      leidoEn: json['leidoEn'] != null ? DateTime.parse(json['leidoEn']) : null,
      giftCode: json['regaloCodigo'],
      giftName: json['regaloNombre'],
    );
  }
}
