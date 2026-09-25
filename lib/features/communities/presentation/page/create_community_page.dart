import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/communities/data/communities_repository.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final LanguageController _l = Get.find<LanguageController>();
  final CommunitiesRepository _repo = CommunitiesRepository.instance;

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();

  final Rxn<File> _image = Rxn<File>();
  final Rxn<File> _cover = Rxn<File>();
  final RxString _category = 'gaming'.obs;
  final RxBool _private = false.obs;
  final RxBool _publishing = false.obs;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pick(Rxn<File> target, {double maxWidth = 1440}) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: maxWidth);
    if (picked != null) target.value = File(picked.path);
  }

  Future<void> _publish() async {
    if (_publishing.value) return;
    if (_name.text.trim().length < 3) return showErrorSnackbarGetx(_l.t('community_err_name'));

    try {
      _publishing.value = true;
      final community = await _repo.create(
        name: _name.text.trim(),
        description: _description.text,
        category: _category.value,
        privacy: _private.value ? 'privada' : 'publica',
        city: _city.text,
        image: _image.value,
        cover: _cover.value,
      );
      Get.back<CommunityEntity>(result: community);
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      _publishing.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.backgroundColorfondo,
      appBar: AppBar(
        backgroundColor: FeedStyle.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.x, color: ThemeColor.textPrimary), onPressed: Get.back),
        title: Text(_l.t('community_create'), style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Obx(() => _publishing.value
              ? LinearProgressIndicator(minHeight: 2, color: ThemeColor.primaryColor, backgroundColor: FeedStyle.hairline)
              : Divider(height: 1, color: FeedStyle.hairline)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
        children: [
          _images(),
          const SizedBox(height: 44),
          _label(_l.t('community_f_name')),
          _field(_name, _l.t('community_f_name_hint'), maxLength: 80),
          const SizedBox(height: 16),
          _label(_l.t('plan_f_category')),
          _categories(),
          const SizedBox(height: 18),
          _label(_l.t('plan_f_description')),
          _field(_description, _l.t('community_f_description_hint'), maxLines: 4, maxLength: 1000),
          const SizedBox(height: 14),
          _label(_l.t('community_f_city')),
          _field(_city, _l.t('community_f_city_hint'), maxLength: 100),
          const SizedBox(height: 18),
          Obx(() => _switchTile(_l.t('community_private'), _private.value, (v) => _private.value = v,
              sub: _private.value ? _l.t('community_private_hint') : _l.t('community_public_hint'))),
          const SizedBox(height: 28),
          Obx(() => GestureDetector(
                onTap: _publishing.value ? null : _publish,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: ThemeColor.primaryGradient, borderRadius: BorderRadius.circular(20)),
                  child: _publishing.value
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : Text(_l.t('community_create_btn'), style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              )),
        ],
      ),
    );
  }

  /// Portada con el avatar de la comunidad encimado.
  Widget _images() {
    return SizedBox(
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _pick(_cover),
              child: Obx(() => Container(
                    decoration: BoxDecoration(
                      color: FeedStyle.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: FeedStyle.hairline),
                      image: _cover.value != null ? DecorationImage(image: FileImage(_cover.value!), fit: BoxFit.cover) : null,
                    ),
                    child: _cover.value != null
                        ? null
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.imagePlus, size: 32, color: ThemeColor.primaryColor),
                              const SizedBox(height: 8),
                              Text(_l.t('community_add_cover'), style: FeedStyle.name.copyWith(color: ThemeColor.primaryColor)),
                            ],
                          ),
                  )),
            ),
          ),
          Positioned(
            left: 20,
            bottom: -36,
            child: GestureDetector(
              onTap: () => _pick(_image, maxWidth: 900),
              child: Obx(() => Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: FeedStyle.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: ThemeColor.backgroundColorfondo, width: 4),
                      image: _image.value != null ? DecorationImage(image: FileImage(_image.value!), fit: BoxFit.cover) : null,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                    ),
                    child: _image.value != null ? null : Icon(LucideIcons.camera, color: ThemeColor.primaryColor, size: 26),
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categories() {
    return Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in CommunityCategory.all)
              GestureDetector(
                onTap: () => _category.value = c.code,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: _category.value == c.code ? LinearGradient(colors: c.colors) : null,
                    color: _category.value == c.code ? null : FeedStyle.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _category.value == c.code ? Colors.transparent : FeedStyle.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon, size: 16, color: _category.value == c.code ? Colors.white : ThemeColor.textPrimary),
                      const SizedBox(width: 6),
                      Text(_l.t('community_cat_${c.code}'),
                          style: GoogleFonts.rubik(
                              fontSize: 13, fontWeight: FontWeight.w500, color: _category.value == c.code ? Colors.white : ThemeColor.textPrimary)),
                    ],
                  ),
                ),
              ),
          ],
        ));
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text, style: GoogleFonts.rubik(fontSize: 13.5, fontWeight: FontWeight.w600, color: ThemeColor.textSecondary)),
      );

  Widget _field(TextEditingController c, String hint, {int maxLines = 1, int? maxLength}) => TextField(
        controller: c,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        style: FeedStyle.body,
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: FeedStyle.meta.copyWith(fontSize: 14.5),
          filled: true,
          fillColor: FeedStyle.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
      );

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged, {String? sub}) => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(color: FeedStyle.surface, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(value ? LucideIcons.lock : LucideIcons.globe, size: 20, color: ThemeColor.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: FeedStyle.name),
                  if (sub != null) Text(sub, style: FeedStyle.meta),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged, activeThumbColor: ThemeColor.primaryColor),
          ],
        ),
      );
}
