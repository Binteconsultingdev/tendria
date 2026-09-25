import 'package:tendria/features/chat/data/model/mensaje_model.dart';
import 'package:tendria/features/chat/domain/entities/mensaje_entity.dart';

class GiftEntity {
  final int id;
  final String code;
  final String name;
  final int cost;

  GiftEntity({required this.id, required this.code, required this.name, required this.cost});

  factory GiftEntity.fromJson(Map<String, dynamic> json) => GiftEntity(
        id: json['id'],
        code: json['codigo'],
        name: json['nombre'],
        cost: json['costo'],
      );
}

class ReceivedGiftEntity {
  final String code;
  final String name;
  final int count;

  ReceivedGiftEntity({required this.code, required this.name, required this.count});

  factory ReceivedGiftEntity.fromJson(Map<String, dynamic> json) => ReceivedGiftEntity(
        code: json['codigo'],
        name: json['nombre'],
        count: json['cantidad'],
      );
}

class SendGiftResult {
  final double balanceLeft;
  final GiftEntity gift;
  final int? chatId;
  final MensajeEntity? message;

  SendGiftResult({required this.balanceLeft, required this.gift, this.chatId, this.message});

  factory SendGiftResult.fromJson(Map<String, dynamic> json) => SendGiftResult(
        balanceLeft: (json['saldoRestante'] as num).toDouble(),
        gift: GiftEntity.fromJson(json['regalo']),
        chatId: json['chatId'],
        message: json['mensaje'] != null ? MensajeModel.fromJson(json['mensaje']) : null,
      );
}
