class MensajeEntity {
  final int id;
  final int chatId;
  final int senderId;
  final String? senderNombre;
  final String? senderFoto;
  final String? mensaje;
  final DateTime enviadoEn;
  final bool esPropio;
final DateTime? leidoEn;
  final String? giftCode; // presente si el mensaje es un regalo
  final String? giftName;
  final String? storyUrl; // presente si el mensaje responde a una historia
  MensajeEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderNombre,
    this.senderFoto,
    this.mensaje,
    required this.enviadoEn,
    required this.esPropio,
    this.leidoEn,
    this.giftCode,
    this.giftName,
    this.storyUrl,
  });
}
