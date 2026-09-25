import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/plans/data/plans_repository.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';
import 'package:tendria/features/plans/presentation/widget/plan_format.dart';

class CreatePlanPage extends StatefulWidget {
  const CreatePlanPage({super.key});

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  final LanguageController _l = Get.find<LanguageController>();
  final PlansRepository _repo = PlansRepository.instance;

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _place = TextEditingController();
  final _capacity = TextEditingController();

  final Rxn<File> _image = Rxn<File>();
  final RxString _category = 'salidas'.obs;
  final Rxn<DateTime> _date = Rxn<DateTime>();
  final Rxn<TimeOfDay> _time = Rxn<TimeOfDay>();
  final RxBool _unlimited = true.obs;
  final RxBool _approval = false.obs;
  final RxBool _publishing = false.obs;
  final RxBool _locating = false.obs;

  double? _lat;
  double? _lng;
  String? _city;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _place.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1440);
    if (picked != null) _image.value = File(picked.path);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.value ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) _date.value = picked;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time.value ?? const TimeOfDay(hour: 20, minute: 0));
    if (picked != null) _time.value = picked;
  }

  Future<void> _useMyLocation() async {
    try {
      _locating.value = true;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        showErrorSnackbarGetx(_l.t('plan_location_denied'));
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
      );
      _lat = position.latitude;
      _lng = position.longitude;

      final marks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (marks.isNotEmpty) {
        final m = marks.first;
        _city = (m.locality?.isNotEmpty == true ? m.locality : m.subAdministrativeArea)?.trim();
        if (_place.text.trim().isEmpty) {
          _place.text = [m.street, _city].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      }
      showSuccessSnackbarGetx(_l.t('plan_location_set'));
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      _locating.value = false;
    }
  }

  Future<void> _publish() async {
    if (_publishing.value) return;

    final title = _title.text.trim();
    if (title.length < 3) return showErrorSnackbarGetx(_l.t('plan_err_title'));
    if (_date.value == null || _time.value == null) return showErrorSnackbarGetx(_l.t('plan_err_datetime'));
    if (_place.text.trim().length < 2) return showErrorSnackbarGetx(_l.t('plan_err_place'));

    final startsAt = DateTime(_date.value!.year, _date.value!.month, _date.value!.day, _time.value!.hour, _time.value!.minute);
    if (startsAt.isBefore(DateTime.now().add(const Duration(minutes: 10)))) {
      return showErrorSnackbarGetx(_l.t('plan_err_future'));
    }

    int? capacity;
    if (!_unlimited.value) {
      capacity = int.tryParse(_capacity.text.trim());
      if (capacity == null || capacity < 2 || capacity > 500) return showErrorSnackbarGetx(_l.t('plan_err_capacity'));
    }

    try {
      _publishing.value = true;
      final plan = await _repo.create(
        title: title,
        description: _description.text,
        category: _category.value,
        startsAt: startsAt,
        placeName: _place.text.trim(),
        lat: _lat,
        lng: _lng,
        city: _city,
        capacity: capacity,
        privacy: _approval.value ? 'aprobacion' : 'publico',
        image: _image.value,
      );
      Get.back<PlanEntity>(result: plan);
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
        title: Text(_l.t('plans_create'), style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
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
          _cover(),
          const SizedBox(height: 22),
          _label(_l.t('plan_f_title')),
          _field(_title, _l.t('plan_f_title_hint'), maxLength: 120),
          const SizedBox(height: 16),
          _label(_l.t('plan_f_category')),
          _categories(),
          const SizedBox(height: 18),
          _label(_l.t('plan_f_when')),
          Row(
            children: [
              Expanded(child: Obx(() => _pickerTile(LucideIcons.calendarDays,
                  _date.value == null ? _l.t('plan_f_date') : '${_date.value!.day} ${PlanFormat.monthShort(_date.value!)} ${_date.value!.year}', _pickDate))),
              const SizedBox(width: 10),
              Expanded(child: Obx(() => _pickerTile(LucideIcons.clock,
                  _time.value == null ? _l.t('plan_f_time') : '${_time.value!.hour.toString().padLeft(2, '0')}:${_time.value!.minute.toString().padLeft(2, '0')}', _pickTime))),
            ],
          ),
          const SizedBox(height: 18),
          _label(_l.t('plan_f_place')),
          _field(_place, _l.t('plan_f_place_hint'), maxLength: 200),
          const SizedBox(height: 8),
          Obx(() => Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _locating.value ? null : _useMyLocation,
                  icon: _locating.value
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(LucideIcons.locateFixed, size: 18, color: ThemeColor.primaryColor),
                  label: Text(_l.t('plan_use_location'), style: GoogleFonts.rubik(color: ThemeColor.primaryColor, fontWeight: FontWeight.w600)),
                ),
              )),
          const SizedBox(height: 10),
          _label(_l.t('plan_f_description')),
          _field(_description, _l.t('plan_f_description_hint'), maxLines: 5, maxLength: 2000),
          const SizedBox(height: 18),
          _label(_l.t('plan_f_capacity')),
          Obx(() => Column(
                children: [
                  _switchTile(_l.t('plan_unlimited'), _unlimited.value, (v) => _unlimited.value = v),
                  if (!_unlimited.value) ...[
                    const SizedBox(height: 10),
                    _field(_capacity, _l.t('plan_f_capacity_hint'), keyboard: TextInputType.number, maxLength: 3),
                  ],
                ],
              )),
          const SizedBox(height: 14),
          Obx(() => _switchTile(_l.t('plan_needs_approval'), _approval.value, (v) => _approval.value = v,
              sub: _l.t('plan_needs_approval_hint'))),
          const SizedBox(height: 28),
          Obx(() => GestureDetector(
                onTap: _publishing.value ? null : _publish,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: ThemeColor.primaryGradient, borderRadius: BorderRadius.circular(20)),
                  child: _publishing.value
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : Text(_l.t('plan_publish'), style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _cover() {
    return GestureDetector(
      onTap: _pickImage,
      child: Obx(() => Container(
            height: 180,
            decoration: BoxDecoration(
              color: FeedStyle.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: FeedStyle.hairline),
              image: _image.value != null ? DecorationImage(image: FileImage(_image.value!), fit: BoxFit.cover) : null,
            ),
            child: _image.value != null
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.imagePlus, size: 34, color: ThemeColor.primaryColor),
                      const SizedBox(height: 8),
                      Text(_l.t('plan_add_cover'), style: FeedStyle.name.copyWith(color: ThemeColor.primaryColor)),
                    ],
                  ),
          )),
    );
  }

  Widget _categories() {
    return Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in PlanCategory.all)
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
                      Text(_l.t('plan_cat_${c.code}'),
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

  Widget _field(TextEditingController c, String hint,
      {int maxLines = 1, int? maxLength, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboard,
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
  }

  Widget _pickerTile(IconData icon, String text, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: FeedStyle.surface, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Icon(icon, size: 18, color: ThemeColor.primaryColor),
              const SizedBox(width: 10),
              Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.body.copyWith(fontSize: 14.5))),
            ],
          ),
        ),
      );

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged, {String? sub}) => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(color: FeedStyle.surface, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
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
