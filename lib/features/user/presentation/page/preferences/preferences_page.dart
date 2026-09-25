import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/user/domain/entities/preferences_step.dart';
import 'package:tendria/features/user/presentation/controller/preferences_controller.dart';
import 'package:tendria/features/user/presentation/widget/AgeWheelWidget.dart';
import 'package:tendria/features/user/presentation/widget/DistanceWheelWidget.dart';

class PreferencesPage extends GetView<PreferencesController> {
  const PreferencesPage({Key? key}) : super(key: key);

  LanguageController get lang => Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: ThemeColor.backgroundColorfondo,
          body: SafeArea(
            child: Obx(() {
              if (!controller.isInitialized.value ||
                  controller.isLoadingUserData.value) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeColor.primaryColor,
                    ),
                  ),
                );
              }

              if (controller.showSuccessScreen.value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offAllNamed(RoutesNames.homePage, arguments: {'tab': 4});
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.availableSteps.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offAllNamed(RoutesNames.homePage, arguments: {'tab': 4});
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              switch (controller.currentStep.value) {
                case PreferencesStep.genderPreference:
                  return _buildGenderPreferenceStep();
                case PreferencesStep.connectionType:
                  return _buildConnectionTypeStep();
                case PreferencesStep.ageRange:
                  return _buildAgeRangeStep();
                case PreferencesStep.photos:
                  return _buildPhotosStep();
                case PreferencesStep.interests:
                  return _buildInterestsStep();
                case PreferencesStep.qualities:
                  return _buildQualitiesStep();
              }
            }),
          ),
        ));
  }


  Widget _buildGenderPreferenceStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(ThemeColor.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Text(
                    lang.t('pref_gender_title'),
                    style: ThemeColor.headingLarge.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: ThemeColor.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingSmall),
                  Text(
                    lang.t('pref_gender_subtitle'),
                    style: ThemeColor.bodyMedium.copyWith(
                      color: ThemeColor.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  ...controller.genderOptions.map((option) {
                    return Column(
                      children: [
                        _buildGenderPreferenceOption(
                          option['icon'] as IconData,
                          option['label'],
                          option['value'],
                          hasCustomInput: option['hasCustomInput'] ?? false,
                        ),
                        SizedBox(height: ThemeColor.paddingSmall),
                      ],
                    );
                  }).toList(),
                  SizedBox(height: ThemeColor.paddingLarge),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: ThemeColor.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lang.t('pref_gender_hint'),
                          style: ThemeColor.bodySmall.copyWith(
                            color: ThemeColor.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildGenderPreferenceOption(
    IconData icon,
    String label,
    String value, {
    bool hasCustomInput = false,
  }) {
    return Obx(() {
      final isSelected = controller.selectedGenderPreference.value == value;
      return GestureDetector(
        onTap: () => controller.selectGenderPreference(value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? ThemeColor.primaryColor
                  : ThemeColor.subtleBorder,
            ),
            color: isSelected
                ? ThemeColor.primaryColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? ThemeColor.tertiaryColor
                    : ThemeColor.textSecondary,
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: ThemeColor.bodyMedium.copyWith(
                    color: ThemeColor.textPrimary,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? ThemeColor.primaryColor
                    : ThemeColor.textSecondary,
              ),
            ],
          ),
        ),
      );
    });
  }


  Widget _buildConnectionTypeStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(ThemeColor.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Text(
                    lang.t('pref_connection_title'),
                    style: ThemeColor.headingLarge.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: ThemeColor.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingSmall),
                  Text(
                    lang.t('pref_connection_subtitle'),
                    style: ThemeColor.bodyMedium.copyWith(
                      color: ThemeColor.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  ...controller.connectionOptions.map((option) {
                    return Column(
                      children: [
                        _buildConnectionOption(
                          option['label'],
                          option['value'],
                        ),
                        SizedBox(height: ThemeColor.paddingSmall),
                      ],
                    );
                  }).toList(),
                  SizedBox(height: ThemeColor.paddingLarge),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: ThemeColor.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lang.t('pref_connection_hint'),
                          style: ThemeColor.bodySmall.copyWith(
                            color: ThemeColor.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildConnectionOption(String label, String value) {
    return Obx(() {
      final isSelected = controller.selectedConnectionType.value == value;
      return InkWell(
        onTap: () => controller.selectConnectionType(value),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ThemeColor.paddingLarge,
            vertical: ThemeColor.paddingMedium + 2,
          ),
          decoration: BoxDecoration(
            color: ThemeColor.cardBackground,
            borderRadius: ThemeColor.mediumBorderRadius,
            border: isSelected
                ? Border.all(color: ThemeColor.tertiaryColor, width: 2)
                : Border.all(color: ThemeColor.subtleBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: ThemeColor.bodyMedium.copyWith(
                    color: ThemeColor.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? ThemeColor.tertiaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? ThemeColor.tertiaryColor
                        : ThemeColor.textSecondary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.circle, color: Colors.white, size: 12)
                    : null,
              ),
            ],
          ),
        ),
      );
    });
  }


  Widget _buildAgeRangeStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(ThemeColor.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Text(
                    lang.t('pref_age_title'),
                    style: ThemeColor.headingLarge.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: ThemeColor.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingSmall),
                  Text(
                    lang.t('pref_age_subtitle'),
                    style: ThemeColor.bodyMedium.copyWith(
                      color: ThemeColor.textSecondary,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            lang.t('bs_age_min'),
                            style: ThemeColor.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ThemeColor.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            lang.t('bs_age_max'),
                            style: ThemeColor.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ThemeColor.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ThemeColor.paddingSmall),
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IgnorePointer(
                          child: Container(
                            height: 60,
                            margin: EdgeInsets.symmetric(
                              horizontal: ThemeColor.paddingMedium,
                            ),
                            decoration: BoxDecoration(
                              color: ThemeColor.cardBackground,
                              borderRadius: ThemeColor.extraLargeBorderRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: AgeWheelWidget(
                                initialAge: controller.minAge.value,
                                onChanged: (age) {
                                  controller.updateMinAge(age);
                                  if (age > controller.maxAge.value) {
                                    controller.updateMaxAge(age);
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: AgeWheelWidget(
                                initialAge: controller.maxAge.value,
                                onChanged: (age) {
                                  controller.updateMaxAge(age);
                                  if (age < controller.minAge.value) {
                                    controller.updateMinAge(age);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => Center(
                      child: Text(
                        'De ${controller.minAge.value} a ${controller.maxAge.value} ${lang.t('years')}',
                        style: ThemeColor.bodyMedium.copyWith(
                          color: ThemeColor.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Text(
                    lang.t('pref_distance_title'),
                    style: ThemeColor.headingSmall.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ThemeColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingSmall),
                  Obx(
                    () => Text(
                      controller.distanceKm.value >= 1000
                          ? lang.t('no_limit')
                          : '${lang.t('pref_distance_up_to')} ${controller.distanceKm.value.toStringAsFixed(controller.distanceKm.value == controller.distanceKm.value.roundToDouble() ? 0 : 1)} km',
                      style: ThemeColor.bodyMedium.copyWith(
                        color: ThemeColor.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingMedium),
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IgnorePointer(
                          child: Container(
                            height: 60,
                            margin: EdgeInsets.symmetric(
                              horizontal: ThemeColor.paddingExtraLarge * 2,
                            ),
                            decoration: BoxDecoration(
                              color: ThemeColor.cardBackground,
                              borderRadius: ThemeColor.extraLargeBorderRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DistanceWheelWidget(
                          initialDistance: controller.distanceKm.value,
                          onChanged: (km) => controller.updateDistance(km),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                ],
              ),
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }


  Widget _buildPhotosStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(ThemeColor.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Text(
                    lang.t('pref_photos_title'),
                    style: ThemeColor.headingLarge.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: ThemeColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingSmall),
                  Text(
                    lang.t('pref_photos_subtitle'),
                    style: ThemeColor.bodyMedium.copyWith(
                      color: ThemeColor.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: ThemeColor.paddingSmall,
                      mainAxisSpacing: ThemeColor.paddingSmall,
                      childAspectRatio: 1,
                    ),
                    itemCount: controller.maxPhotos,
                    itemBuilder: (context, index) {
                      return Obx(() {
                        final photos = controller.selectedPhotos;
                        final isPicking = controller.isPickingPhotos.value;
                        if (index < photos.length) {
                          return _buildPhotoItem(photos[index], index);
                        }
                        if (isPicking) {
                          return _buildLoadingPhotoSlot();
                        }
                        return _buildAddPhotoButton();
                      });
                    },
                  ),
                  SizedBox(height: ThemeColor.paddingLarge),
                  Obx(
                    () => Center(
                      child: Text(
                        '${controller.selectedPhotos.length}/${controller.maxPhotos} ${lang.t('photos')}',
                        style: ThemeColor.bodyMedium.copyWith(
                          color: ThemeColor.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildLoadingPhotoSlot() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColor.primaryColor.withOpacity(0.05),
        borderRadius: ThemeColor.mediumBorderRadius,
        border: Border.all(
          color: ThemeColor.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(ThemeColor.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(String photoPath, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: ThemeColor.cardBackground,
            borderRadius: ThemeColor.mediumBorderRadius,
            border: Border.all(color: ThemeColor.subtleBorder, width: 1),
          ),
          child: ClipRRect(
            borderRadius: ThemeColor.mediumBorderRadius,
            child: Image.file(
              File(photoPath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => controller.removePhoto(index),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: controller.showPhotoOptions,
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColor.cardBackground,
          borderRadius: ThemeColor.mediumBorderRadius,
          border: Border.all(color: ThemeColor.subtleBorder, width: 1),
        ),
        child: Icon(Icons.add, color: ThemeColor.textSecondary, size: 32),
      ),
    );
  }


  Widget _buildInterestsStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(ThemeColor.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Text(
                    lang.t('interests_page_title'),
                    style: ThemeColor.headingLarge.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ThemeColor.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingSmall),
                  Text(
                    lang.t('interests_page_subtitle'),
                    style: ThemeColor.bodyMedium.copyWith(
                      color: ThemeColor.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ThemeColor.paddingLarge,
                      vertical: ThemeColor.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeColor.cardBackground,
                      borderRadius: ThemeColor.mediumBorderRadius,
                      border: Border.all(color: ThemeColor.subtleBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: ThemeColor.textSecondary),
                        SizedBox(width: ThemeColor.paddingSmall),
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: ThemeColor.textPrimary),
                            decoration: InputDecoration(
                              hintText: lang.t('interests_search_hint'),
                              hintStyle: ThemeColor.bodyMedium.copyWith(
                                color: ThemeColor.textSecondary,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingLarge),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.t('interests_popular'),
                          style: ThemeColor.bodyMedium.copyWith(
                            color: ThemeColor.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${controller.selectedInterests.length}/${controller.maxInterests} ${lang.t('bs_interests_selected')}',
                          style: ThemeColor.bodyMedium.copyWith(
                            color: ThemeColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingMedium),
                  Obx(() {
                    if (controller.isLoadingInterests.value) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(ThemeColor.paddingExtraLarge),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ThemeColor.primaryColor,
                            ),
                          ),
                        ),
                      );
                    }
                    if (controller.interests.isEmpty) {
                      return Center(
                        child: Text(
                          lang.t('pref_no_interests'),
                          style: ThemeColor.bodyMedium.copyWith(
                            color: ThemeColor.textSecondary,
                          ),
                        ),
                      );
                    }
                    return Wrap(
                      spacing: ThemeColor.paddingSmall,
                      runSpacing: ThemeColor.paddingSmall,
                      children: controller.interests.map((interest) {
                        final isSelected =
                            controller.selectedInterests.contains(interest.id);
                        return _buildInterestChip(
                          interest.name,
                          _getInterestIcon(interest.name),
                          isSelected,
                          () => controller.toggleInterest(interest.id),
                        );
                      }).toList(),
                    );
                  }),
                  SizedBox(height: ThemeColor.paddingLarge),
                  Center(
                    child: Text(
                      lang.t('interests_custom_hint'),
                      style: ThemeColor.bodySmall.copyWith(
                        color: ThemeColor.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                ],
              ),
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildInterestChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ThemeColor.paddingMedium,
          vertical: ThemeColor.paddingSmall + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ThemeColor.tertiaryColor : ThemeColor.cardBackground,
          borderRadius: ThemeColor.circularBorderRadius,
          border: Border.all(
            color: isSelected ? ThemeColor.tertiaryColor : ThemeColor.subtleBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : ThemeColor.textPrimary,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: ThemeColor.bodyMedium.copyWith(
                color: isSelected ? Colors.white : ThemeColor.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getInterestIcon(String interest) {
    final icons = {
      'Pintura': Icons.brush,
      'Fotografía': Icons.camera_alt,
      'Arte': Icons.palette,
      'Cine': Icons.movie,
      'Videojuegos': Icons.videogame_asset,
      'Anime': Icons.auto_awesome,
      'Música en vivo': Icons.mic,
      'Rock': Icons.music_note,
      'Reggaetón': Icons.headphones,
      'Conciertos': Icons.music_note,
      'Festivales': Icons.festival,
      'Bailar': Icons.music_note,
      'Gimnasio': Icons.fitness_center,
      'Correr': Icons.directions_run,
      'Yoga': Icons.self_improvement,
      'Meditación': Icons.spa,
      'Deportes': Icons.sports_soccer,
      'Senderismo': Icons.terrain,
      'Viajar': Icons.flight_takeoff,
      'Playa': Icons.beach_access,
      'Café': Icons.coffee,
      'Vino': Icons.wine_bar,
      'Cocinar': Icons.restaurant_menu,
      'Foodie': Icons.restaurant,
      'Lectura': Icons.menu_book,
      'Libros': Icons.book,
      'Psicología': Icons.psychology,
      'Programación': Icons.code,
      'Emprendimiento': Icons.rocket_launch,
      'Startups': Icons.trending_up,
      'Criptomonedas': Icons.currency_bitcoin,
      'Autos deportivos': Icons.directions_car,
      'Nómada digital': Icons.laptop_mac,
      'Perros': Icons.pets,
      'Gatos': Icons.pets,
      'Relación seria': Icons.favorite,
      'Algo casual': Icons.sentiment_satisfied_alt,
      'Escribir': Icons.edit,
      'Museos y galerías': Icons.museum,
    };
    return icons[interest] ?? Icons.favorite;
  }


  Widget _buildQualitiesStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(ThemeColor.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Text(
                    lang.t('qualities_page_title'),
                    style: ThemeColor.headingLarge.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: ThemeColor.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingSmall),
                  Text(
                    lang.t('qualities_page_subtitle'),
                    style: ThemeColor.bodyMedium.copyWith(
                      color: ThemeColor.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingExtraLarge),
                  Obx(
                    () => Text(
                      '${lang.t('qualities_counter_label')}        ${controller.selectedQualities.length}/${controller.maxQualities} ${lang.t('bs_interests_selected')}',
                      style: ThemeColor.bodyMedium.copyWith(
                        color: ThemeColor.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: ThemeColor.paddingMedium),
                  Obx(() {
                    if (controller.isLoadingQualities.value) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(ThemeColor.paddingExtraLarge),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ThemeColor.primaryColor,
                            ),
                          ),
                        ),
                      );
                    }
                    if (controller.qualities.isEmpty) {
                      return Center(
                        child: Text(
                          lang.t('pref_no_qualities'),
                          style: ThemeColor.bodyMedium.copyWith(
                            color: ThemeColor.textSecondary,
                          ),
                        ),
                      );
                    }
                    return Wrap(
                      spacing: ThemeColor.paddingSmall,
                      runSpacing: ThemeColor.paddingSmall,
                      children: controller.qualities.map((quality) {
                        final isSelected =
                            controller.selectedQualities.contains(quality.id);
                        return _buildQualityChip(
                          quality.name,
                          isSelected,
                          () => controller.toggleQuality(quality.id),
                        );
                      }).toList(),
                    );
                  }),
                  SizedBox(height: ThemeColor.paddingExtraLarge * 2),
                ],
              ),
            ),
          ),
        ),
        _buildFinalButtons(),
      ],
    );
  }

  Widget _buildQualityChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ThemeColor.paddingLarge,
          vertical: ThemeColor.paddingMedium - 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ThemeColor.tertiaryColor : ThemeColor.cardBackground,
          borderRadius: ThemeColor.circularBorderRadius,
          border: Border.all(
            color: isSelected ? ThemeColor.tertiaryColor : ThemeColor.subtleBorder,
          ),
        ),
        child: Text(
          label,
          style: ThemeColor.bodyMedium.copyWith(
            color: isSelected ? Colors.white : ThemeColor.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(ThemeColor.paddingLarge),
      decoration: BoxDecoration(color: ThemeColor.backgroundColorfondo),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_buildBackButton(), SizedBox(), _buildNextButton()],
      ),
    );
  }

  Widget _buildFinalButtons() {
    return Container(
      padding: EdgeInsets.all(ThemeColor.paddingLarge),
      decoration: BoxDecoration(color: ThemeColor.backgroundColorfondo),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBackButton(),
          SizedBox(),
          Obx(() {
            final isSaving = controller.isLoading.value;
            return GestureDetector(
              onTap: isSaving ? null : controller.submitPreferences,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSaving
                      ? ThemeColor.tertiaryColor.withOpacity(0.6)
                      : ThemeColor.tertiaryColor,
                  shape: BoxShape.circle,
                ),
                child: isSaving
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Icon(Icons.check, color: Colors.white),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Obx(
      () => controller.currentStepIndex.value > 0
          ? GestureDetector(
              onTap: controller.previousStep,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ThemeColor.tertiaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            )
          : SizedBox(width: 56),
    );
  }

  Widget _buildNextButton() {
    return Obx(() {
      final isSaving = controller.isLoading.value;
      final isLastStep = controller.currentStepIndex.value >=
          controller.availableSteps.length - 1;

      return GestureDetector(
        onTap: isSaving
            ? null
            : () {
                if (!controller.validateCurrentStep()) return;
                controller.submitPreferences();
              },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSaving
                ? ThemeColor.tertiaryColor.withOpacity(0.6)
                : ThemeColor.tertiaryColor,
            shape: BoxShape.circle,
          ),
          child: isSaving
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Icon(
                  isLastStep ? Icons.check : Icons.arrow_forward,
                  color: Colors.white,
                ),
        ),
      );
    });
  }
}