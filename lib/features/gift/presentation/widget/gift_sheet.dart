import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/gift/data/gift_repository.dart';
import 'package:tendria/features/gift/domain/entities/gift_entities.dart';
import 'package:tendria/features/gift/presentation/widget/gift_icon.dart';
import 'package:tendria/features/user/presentation/controller/balance_controller.dart';

/// Abre la hoja para elegir y enviar un regalo. Devuelve el resultado si se envió.
/// [origin]: 'chat' | 'perfil' | 'post'
Future<SendGiftResult?> showGiftSheet(
  BuildContext context, {
  required int toUserId,
  required String toName,
  required String origin,
  int? postId,
}) {
  return showModalBottomSheet<SendGiftResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ThemeColor.cardBackground,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _GiftSheet(toUserId: toUserId, toName: toName, origin: origin, postId: postId),
  );
}

class _GiftSheet extends StatefulWidget {
  final int toUserId;
  final String toName;
  final String origin;
  final int? postId;

  const _GiftSheet({required this.toUserId, required this.toName, required this.origin, this.postId});

  @override
  State<_GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<_GiftSheet> {
  final GiftRepository _repo = GiftRepository.instance;
  final LanguageController _l = Get.find<LanguageController>();

  final RxList<GiftEntity> _catalog = <GiftEntity>[].obs;
  final Rxn<GiftEntity> _selected = Rxn<GiftEntity>();
  final Rxn<SendGiftResult> _sent = Rxn<SendGiftResult>();
  final RxBool _loading = true.obs;
  final RxBool _sending = false.obs;
  final RxnString _error = RxnString();

  BalanceController? get _balance => Get.isRegistered<BalanceController>() ? Get.find<BalanceController>() : null;

  @override
  void initState() {
    super.initState();
    _balance?.fetchBalance();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      _loading.value = true;
      _error.value = null;
      _catalog.assignAll(await _repo.getCatalog());
    } catch (e) {
      _error.value = cleanExceptionMessage(e);
    } finally {
      _loading.value = false;
    }
  }

  double get _credits => _balance?.currentBalance ?? 0;

  bool _canAfford(GiftEntity g) => _credits >= g.cost;

  Future<void> _send() async {
    final gift = _selected.value;
    if (gift == null || _sending.value) return;

    if (!_canAfford(gift)) {
      Navigator.of(context).pop();
      Get.toNamed(RoutesNames.purchasePage);
      return;
    }

    try {
      _sending.value = true;
      final result = await _repo.send(
        toUserId: widget.toUserId,
        code: gift.code,
        origin: widget.origin,
        postId: widget.postId,
      );
      HapticFeedback.heavyImpact();
      await _balance?.fetchBalance();
      _sent.value = result;

      // Muestra la confirmación un momento y cierra devolviendo el resultado
      await Future.delayed(const Duration(milliseconds: 1700));
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      _sending.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.68,
      child: Obx(() => AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _sent.value != null ? _success(_sent.value!) : _picker(),
          )),
    );
  }

  Widget _picker() {
    return Column(
      key: const ValueKey('picker'),
      children: [
        const SizedBox(height: 10),
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(color: ThemeColor.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_l.t('gift_send_title'),
                        style: GoogleFonts.rubik(fontSize: 19, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${_l.t('gift_to')} ${widget.toName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rubik(fontSize: 13.5, color: ThemeColor.textSecondary)),
                  ],
                ),
              ),
              _balanceChip(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            if (_loading.value) return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
            if (_error.value != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error.value!, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    OutlinedButton(onPressed: _loadCatalog, child: Text(_l.t('feed_retry'))),
                  ],
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemCount: _catalog.length,
              itemBuilder: (_, i) => _giftCard(_catalog[i]),
            );
          }),
        ),
        _sendButton(),
      ],
    );
  }

  Widget _balanceChip() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        Get.toNamed(RoutesNames.purchasePage);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ThemeColor.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.coins, size: 16, color: ThemeColor.primaryColor),
            const SizedBox(width: 6),
            Obx(() => Text('${(_balance?.balance.value?.balance ?? 0).toStringAsFixed(0)}',
                style: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: ThemeColor.primaryColor))),
            const SizedBox(width: 6),
            Icon(LucideIcons.plus, size: 14, color: ThemeColor.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _giftCard(GiftEntity gift) {
    return Obx(() {
      final selected = _selected.value?.id == gift.id;
      final affordable = _canAfford(gift);

      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _selected.value = gift;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            color: selected ? ThemeColor.primaryColor.withValues(alpha: 0.08) : ThemeColor.backgroundColorfondo,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? ThemeColor.primaryColor : Colors.transparent, width: 2),
          ),
          child: Opacity(
            opacity: affordable ? 1 : 0.5,
            child: Column(
              children: [
                Expanded(child: AnimatedScale(scale: selected ? 1.12 : 1, duration: const Duration(milliseconds: 180), child: GiftIcon(code: gift.code, size: 62))),
                const SizedBox(height: 6),
                Text(gift.name,
                    style: GoogleFonts.rubik(fontSize: 13.5, fontWeight: FontWeight.w600, color: ThemeColor.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.coins, size: 12, color: ThemeColor.textSecondary),
                    const SizedBox(width: 4),
                    Text('${gift.cost}', style: GoogleFonts.rubik(fontSize: 12.5, color: ThemeColor.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _sendButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Obx(() {
          final gift = _selected.value;
          final affordable = gift == null || _canAfford(gift);
          final enabled = gift != null && !_sending.value;

          final label = gift == null
              ? _l.t('gift_pick')
              : affordable
                  ? '${_l.t('gift_send_btn')} ${gift.name} · ${gift.cost} ${_l.t('gift_credits')}'
                  : _l.t('gift_recharge');

          return GestureDetector(
            onTap: enabled ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: enabled ? ThemeColor.primaryGradient : null,
                color: enabled ? null : ThemeColor.textSecondary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _sending.value
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Text(label,
                      style: GoogleFonts.rubik(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: enabled ? Colors.white : ThemeColor.textSecondary,
                      )),
            ),
          );
        }),
      ),
    );
  }

  Widget _success(SendGiftResult result) {
    return Center(
      key: const ValueKey('success'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween(begin: 0, end: 1),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: GiftIcon(code: result.gift.code, size: 130),
          ),
          const SizedBox(height: 20),
          Text(_l.t('gift_sent'), style: GoogleFonts.rubik(fontSize: 22, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
          const SizedBox(height: 6),
          Text('${result.gift.name} → ${widget.toName}',
              style: GoogleFonts.rubik(fontSize: 15, color: ThemeColor.textSecondary)),
        ],
      ),
    );
  }
}
