import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/gift/data/gift_repository.dart';
import 'package:tendria/features/gift/domain/entities/gift_entities.dart';
import 'package:tendria/features/gift/presentation/widget/gift_icon.dart';

/// Regalos que ha recibido una persona, para mostrar en su perfil. No muestra nada si no tiene.
class ReceivedGiftsStrip extends StatefulWidget {
  final int userId;
  const ReceivedGiftsStrip({super.key, required this.userId});

  @override
  State<ReceivedGiftsStrip> createState() => _ReceivedGiftsStripState();
}

class _ReceivedGiftsStripState extends State<ReceivedGiftsStrip> {
  late final Future<List<ReceivedGiftEntity>> _future = GiftRepository.instance.getReceived(widget.userId);

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();

    return FutureBuilder<List<ReceivedGiftEntity>>(
      future: _future,
      builder: (_, snapshot) {
        final gifts = snapshot.data;
        if (gifts == null || gifts.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: ThemeColor.cardBackground, borderRadius: ThemeColor.mediumBorderRadius, boxShadow: [ThemeColor.lightShadow]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.t('gift_received_title'),
                  style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final g in gifts)
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                      decoration: BoxDecoration(color: ThemeColor.backgroundColorfondo, borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GiftIcon(code: g.code, size: 34),
                          const SizedBox(width: 6),
                          Text('×${g.count}', style: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
