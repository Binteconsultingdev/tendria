import 'package:tendria/features/auth/data/email_availability.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/services/translation_service.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper.dart';
import 'package:tendria/features/auth/domain/entities/user/create_user_entity.dart';
import 'package:tendria/features/auth/domain/entities/user/registration_step.dart';
import 'package:tendria/features/auth/domain/usecase/create_user_usecase.dart';
import 'package:tendria/features/catalog/domain/entities/catalog_entity.dart';
import 'package:tendria/features/catalog/domain/usecase/fetch_interests_usecase.dart';
import 'package:tendria/features/catalog/domain/usecase/fetch_qualities_usecase.dart';
import 'package:tendria/features/facebookEvent/domain/usecase/log_register_usecase.dart';

class RegisterController extends GetxController {
  final CreateUserUsecase createUserUsecase;
  final FetchQualitiesUsecase fetchQualitiesUsecase;
  final FetchInterestsUsecase fetchInterestsUsecase;
  final LogRegisterUsecase logRegisterUsecase;

  RegisterController({
    required this.createUserUsecase,
    required this.fetchQualitiesUsecase,
    required this.fetchInterestsUsecase,
    required this.logRegisterUsecase,
  });

  TranslationService get _translator => Get.find<TranslationService>();
  LanguageController get _l => Get.find<LanguageController>();

  final Rx<RegistrationStep> currentStep = RegistrationStep.basicInfo.obs;
  final RxInt currentStepIndex = 0.obs;
  late FixedExtentScrollController heightScrollController;

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  late final TextEditingController heightController;
  late final TextEditingController cityController;
  late final TextEditingController customGenderController;
  late final TextEditingController bioController;

  late final FocusNode nameFocusNode;
  late final FocusNode emailFocusNode;
  late final FocusNode passwordFocusNode;
  late final FocusNode confirmPasswordFocusNode;
  late final FocusNode heightFocusNode;
  late final FocusNode cityFocusNode;
  late final FocusNode bioFocusNode;
  late final FocusNode customGenderFocusNode;

  final RxBool isLoading = false.obs;
  final RxBool showPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;
  final RxBool isLoadingLocation = false.obs;
  final RxBool locationObtained = false.obs;
  final RxBool isLoadingQualities = false.obs;
  final RxBool isLoadingInterests = false.obs;

  final Rx<DateTime?> dateOfBirth = Rx<DateTime?>(null);
  final RxString selectedGender = ''.obs;
  final RxString selectedLanguage = 'Español'.obs;
  final RxList<int> selectedInterests = <int>[].obs;
  final RxList<int> selectedQualities = <int>[].obs;

  final int maxInterests = 5;
  final int maxQualities = 3;

  final RxInt bioCharCount = 0.obs;
  final RxBool showCustomGender = false.obs;

  final RxList<CatalogEntity> qualities = <CatalogEntity>[].obs;
  final RxList<CatalogEntity> interests = <CatalogEntity>[].obs;

  final RxMap<String, String> translatedInterests = <String, String>{}.obs;
  final RxMap<String, String> translatedQualities = <String, String>{}.obs;

  final RxString latitude = ''.obs;
  final RxString longitude = ''.obs;
  final RxString city = ''.obs;

  final RxBool emailError = false.obs;
  final RxBool passwordError = false.obs;
  final RxBool confirmPasswordError = false.obs;
  final RxBool nameError = false.obs;
  final RxBool bioError = false.obs;

  final RxString emailErrorMessage = ''.obs;
  final RxString passwordErrorMessage = ''.obs;
  final RxString confirmPasswordErrorMessage = ''.obs;
  final RxString nameErrorMessage = ''.obs;
  final RxString bioErrorMessage = ''.obs;

  final RxInt selectedHeight = 170.obs;
bool _containsNumericWord(String text) {
  final lower = text.toLowerCase().trim();
 
  const falsePositives = {
    'una', 'un', 'uno',  
    'once',             
                       
  };

  const numericRoots =
      r'(cero|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|'
      r'diez|once|doce|trece|catorce|quince|dieci|veint|'
      r'treinta|cuarenta|cincuenta|sesenta|setenta|ochenta|noventa|'
      r'cien(to)?|doscient|trescient|cuatrocient|quinient|'
      r'seiscient|setecient|ochocient|novecient|mil|millon?e?s?|'
      r'zero|one|two|three|four|five|six|seven|eight|nine|ten|'
      r'eleven|twelve|thir(teen|ty)?|four(teen|ty)?|fif(teen|ty)?|'
      r'six(teen|ty)?|seven(teen|ty)?|eigh(teen|ty)?|nine(teen|ty)?|'
      r'twenty|hundred|thousand|million|billion)';
 
  if (RegExp(r'\d').hasMatch(lower)) return true;

  final singlePattern = RegExp(
    r'\b' + numericRoots + r'\b',
    caseSensitive: false,
    unicode: true,
  );

  final matches = singlePattern.allMatches(lower);
  for (final match in matches) {
    final word = match.group(0)!.toLowerCase();
    if (!falsePositives.contains(word)) {
      return true;
    }
  }

  return false;
}

  final List<Map<String, dynamic>> genderOptions = [
    {'label': 'Masculino', 'value': 'Hombre', 'icon': Icons.male},
    {'label': 'Femenino', 'value': 'Mujer', 'icon': Icons.female},
    {
      'label': 'Persona no binaria',
      'value': 'No_binario',
      'icon': Icons.transgender,
    },
  ];

  @override
  void onInit() {
    super.onInit();

    selectedLanguage.value = _l.deviceLanguage;
    heightScrollController = FixedExtentScrollController(initialItem: 70);
    _initializeControllers();

    _loadCatalogs();
  }

  void _initializeControllers() {
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    heightController = TextEditingController(text: '170');
    cityController = TextEditingController();
    bioController = TextEditingController();
    customGenderController = TextEditingController();

    nameFocusNode = FocusNode();
    emailFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    confirmPasswordFocusNode = FocusNode();
    heightFocusNode = FocusNode();
    cityFocusNode = FocusNode();
    bioFocusNode = FocusNode();
    customGenderFocusNode = FocusNode();

    emailController.addListener(_validateEmail);
    emailFocusNode.addListener(_onEmailFocusChange);
    passwordController.addListener(_validatePassword);
    confirmPasswordController.addListener(_validateConfirmPassword);
    nameController.addListener(_validateName);
    bioController.addListener(_validateBio);
  }

  @override
  void onClose() {
    emailController.removeListener(_validateEmail);
    emailFocusNode.removeListener(_onEmailFocusChange);
    passwordController.removeListener(_validatePassword);
    confirmPasswordController.removeListener(_validateConfirmPassword);
    nameController.removeListener(_validateName);
    bioController.removeListener(_validateBio);

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    heightController.dispose();
    cityController.dispose();
    bioController.dispose();
    customGenderController.dispose();

    nameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    heightFocusNode.dispose();
    cityFocusNode.dispose();
    bioFocusNode.dispose();
    customGenderFocusNode.dispose();

    heightScrollController.dispose();

    super.onClose();
  }

  Future<void> _loadCatalogs() async {
    print('[RegisterController] 🔄 _loadCatalogs() iniciando...');
    await Future.wait([_loadQualities(), _loadInterests()]);
    print('[RegisterController] ✅ _loadCatalogs() completado');
  }

  Future<void> _loadQualities() async {
    try {
      isLoadingQualities.value = true;
      print('[RegisterController] 🔄 Cargando cualidades desde API...');
      final result = await fetchQualitiesUsecase.execute();
      qualities.value = result;
      print(
        '[RegisterController] ✅ Cualidades cargadas: ${result.length} items',
      );
      result.forEach((q) => print('  - cualidad: ${q.name}'));
      await _translateQualitiesCatalog();
    } catch (e) {
      print('[RegisterController] ❌ Error cargando cualidades: $e');
    } finally {
      isLoadingQualities.value = false;
    }
  }

  Future<void> _loadInterests() async {
    try {
      isLoadingInterests.value = true;
      print('[RegisterController] 🔄 Cargando intereses desde API...');
      final result = await fetchInterestsUsecase.execute();
      interests.value = result;
      print(
        '[RegisterController] ✅ Intereses cargados: ${result.length} items',
      );
      result.forEach((i) => print('  - interés: ${i.name}'));
      await _translateInterestsCatalog();
    } catch (e) {
      print('[RegisterController] ❌ Error cargando intereses: $e');
    } finally {
      isLoadingInterests.value = false;
    }
  }

  Future<void> _waitForTranslator() async {
    print(
      '[RegisterController] 🔍 TranslationService.isReady = ${_translator.isReady.value}',
    );
    if (!_translator.isReady.value) {
      print(
        '[RegisterController] ⏳ Esperando que TranslationService esté listo...',
      );
      await _translator.isReady.stream.firstWhere((ready) => ready);
      print('[RegisterController] ✅ TranslationService ya está listo');
    }
  }

  Future<void> _translateInterestsCatalog() async {
    print('[RegisterController] 🌐 _translateInterestsCatalog() iniciando...');

    if (interests.isEmpty) {
      print('[RegisterController] ⚠️ interests está vacío, nada que traducir');
      return;
    }

    await _waitForTranslator();

    final lang = _l.lang;
    print(
      '[RegisterController] 🌍 Idioma detectado por LanguageController: "$lang"',
    );

    final names = interests.map((i) => i.name).toList();
    print('[RegisterController] 📋 Nombres a traducir: $names');

    final results = await _translator.translateList(names);
    print('[RegisterController] 📋 Resultados traducidos: $results');

    translatedInterests.assignAll({
      for (int i = 0; i < names.length; i++) names[i]: results[i],
    });

    print('[RegisterController] ✅ translatedInterests asignado:');
    translatedInterests.forEach((k, v) => print('  "$k" → "$v"'));
  }

  Future<void> _translateQualitiesCatalog() async {
    print('[RegisterController] 🌐 _translateQualitiesCatalog() iniciando...');

    if (qualities.isEmpty) {
      print('[RegisterController] ⚠️ qualities está vacío, nada que traducir');
      return;
    }

    await _waitForTranslator();

    final lang = _l.lang;
    print(
      '[RegisterController] 🌍 Idioma detectado por LanguageController: "$lang"',
    );

    final names = qualities.map((q) => q.name).toList();
    print('[RegisterController] 📋 Nombres a traducir: $names');

    final results = await _translator.translateList(names);
    print('[RegisterController] 📋 Resultados traducidos: $results');

    translatedQualities.assignAll({
      for (int i = 0; i < names.length; i++) names[i]: results[i],
    });

    print('[RegisterController] ✅ translatedQualities asignado:');
    translatedQualities.forEach((k, v) => print('  "$k" → "$v"'));
  }

  String getInterestLabel(String name) => translatedInterests[name] ?? name;

  String getQualityLabel(String name) => translatedQualities[name] ?? name;

  // ---- correo: se valida desde el principio (formato y que no esté ya registrado) ----
  String? _checkedEmail;
  bool _checkedEmailFree = true;

  Future<bool> _ensureEmailFree() async {
    final email = emailController.text.trim();
    if (email.isEmpty || emailError.value) return true; // el formato inválido ya se muestra por separado
    if (_checkedEmail == email) {
      if (!_checkedEmailFree) {
        emailError.value = true;
        emailErrorMessage.value = _l.t('val_email_taken');
      }
      return _checkedEmailFree;
    }

    final free = await isEmailAvailable(email);
    _checkedEmail = email;
    _checkedEmailFree = free;

    // El usuario pudo seguir escribiendo mientras se consultaba
    if (!free && emailController.text.trim() == email) {
      emailError.value = true;
      emailErrorMessage.value = _l.t('val_email_taken');
    }
    return free;
  }

  void _onEmailFocusChange() {
    if (!emailFocusNode.hasFocus) _ensureEmailFree();
  }

  Future<void> nextStep() async {
    if (_validateCurrentStep()) {
      if (currentStep.value == RegistrationStep.basicInfo && !await _ensureEmailFree()) return;
      if (currentStepIndex.value < 4) {
        currentStepIndex.value++;
        currentStep.value = RegistrationStep.values[currentStepIndex.value];

        if (currentStep.value == RegistrationStep.personalInfo) {
          _autoGetLocation();
        }
      }
    }
  }

  void previousStep() {
    if (currentStepIndex.value > 0) {
      currentStepIndex.value--;
      currentStep.value = RegistrationStep.values[currentStepIndex.value];
    }
  }

  void skipStep() {
    if (currentStepIndex.value < 4) {
      currentStepIndex.value++;
      currentStep.value = RegistrationStep.values[currentStepIndex.value];

      if (currentStep.value == RegistrationStep.personalInfo) {
        _autoGetLocation();
      }
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case RegistrationStep.basicInfo:
        return _validateBasicInfo();
      case RegistrationStep.personalInfo:
        return _validatePersonalInfo();
      case RegistrationStep.physicalInfo:
        return _validatePhysicalInfo();
      case RegistrationStep.interests:
        return _validateInterests();
      case RegistrationStep.qualities:
        return true;
    }
  }

  bool _validateBasicInfo() {
    bool isValid = true;

    if (nameController.text.isEmpty || nameController.text.length < 3) {
      nameError.value = true;
      nameErrorMessage.value = nameController.text.isEmpty
          ? _l.t('val_name_required')
          : _l.t('val_name_min');
      isValid = false;
    }

    if (emailController.text.isEmpty) {
      emailError.value = true;
      emailErrorMessage.value = _l.t('val_email_required');
      isValid = false;
    } else if (emailError.value) {
      isValid = false;
    }

    if (passwordController.text.isEmpty || passwordController.text.length < 8) {
      passwordError.value = true;
      passwordErrorMessage.value = passwordController.text.isEmpty
          ? _l.t('val_password_required')
          : _l.t('val_min_8');
      isValid = false;
    }

    if (confirmPasswordController.text != passwordController.text) {
      confirmPasswordError.value = true;
      confirmPasswordErrorMessage.value = _l.t('val_passwords_no_match');
      isValid = false;
    }

    return isValid;
  }

  bool _validatePersonalInfo() {
    if (dateOfBirth.value == null) {
      showErrorSnackbar(_l.t('val_dob_required'));
      return false;
    }

    if (selectedGender.value.isEmpty) {
      showErrorSnackbar(_l.t('val_gender_required'));
      return false;
    }

    if (selectedGender.value == 'Otro' &&
        customGenderController.text.trim().isEmpty) {
      showErrorSnackbar(_l.t('val_custom_gender_required'));
      return false;
    }

    if (bioController.text.trim().isEmpty) {
      showErrorSnackbar(_l.t('val_bio_required'));
      return false;
    }

    if (bioController.text.trim().length < 10) {
      showErrorSnackbar(_l.t('val_bio_min'));
      return false;
    }

    if (bioController.text.length > 500) {
      showErrorSnackbar(_l.t('val_bio_max'));
      return false;
    }

    if (_containsNumericWord(bioController.text.trim())) {
      showErrorSnackbar(_l.t('bs_no_numbers'));
      return false;
    }

    return true;
  }

  bool _validatePhysicalInfo() {
    if (heightController.text.isEmpty) {
      showErrorSnackbar(_l.t('val_height_required'));
      return false;
    }

    final height = int.tryParse(heightController.text);
    if (height == null || height < 100 || height > 250) {
      showErrorSnackbar(_l.t('val_height_invalid'));
      return false;
    }

    return true;
  }

  bool _validateInterests() {
    if (selectedInterests.isEmpty) {
      showErrorSnackbar(_l.t('val_interest_required'));
      return false;
    }
    return true;
  }

  void _validateBio() {
    bioCharCount.value = bioController.text.length;

    if (bioController.text.isEmpty) {
      bioError.value = true;
      bioErrorMessage.value = _l.t('val_bio_required');
      return;
    }
    if (bioController.text.length < 10) {
      bioError.value = true;
      bioErrorMessage.value = _l.t('val_min_10');
      return;
    }
    if (bioController.text.length > 500) {
      bioError.value = true;
      bioErrorMessage.value = _l.t('val_max_500');
      return;
    }
    if (_containsNumericWord(bioController.text)) {
      bioError.value = true;
      bioErrorMessage.value = _l.t('bs_no_numbers');
      return;
    }

    bioError.value = false;
  }

  void _validateName() {
    if (nameController.text.isEmpty) {
      nameError.value = false;
      return;
    }
    if (nameController.text.length < 3) {
      nameError.value = true;
      nameErrorMessage.value = _l.t('val_name_min');
    } else {
      nameError.value = false;
    }
  }

  void _validateEmail() {
    if (emailController.text.isEmpty) {
      emailError.value = false;
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text)) {
      emailError.value = true;
      emailErrorMessage.value = _l.t('val_email_invalid');
    } else {
      emailError.value = false;
    }
  }

  void _validatePassword() {
    if (passwordController.text.isEmpty) {
      passwordError.value = false;
      return;
    }
    if (passwordController.text.length < 8) {
      passwordError.value = true;
      passwordErrorMessage.value = _l.t('val_min_8');
    } else {
      passwordError.value = false;
    }
  }

  void _validateConfirmPassword() {
    if (confirmPasswordController.text.isEmpty) {
      confirmPasswordError.value = false;
      return;
    }
    if (confirmPasswordController.text != passwordController.text) {
      confirmPasswordError.value = true;
      confirmPasswordErrorMessage.value = _l.t('val_passwords_no_match');
    } else {
      confirmPasswordError.value = false;
    }
  }

  Future<void> _autoGetLocation() async {
    try {
      isLoadingLocation.value = true;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude.value = position.latitude.toString();
      longitude.value = position.longitude.toString();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        city.value = placemark.locality?.isNotEmpty == true
            ? placemark.locality!
            : placemark.administrativeArea ?? '';
      }

      locationObtained.value = true;
    } catch (e) {
      print('[RegisterController] ❌ Error obteniendo ubicación: $e');
      city.value = '';
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void selectHeight(int height) {
    heightController.text = height.toString();
    selectedHeight.value = height;
  }

  void selectDateOfBirth(DateTime date) {
    dateOfBirth.value = date;
  }

  void selectGender(String gender) {
    selectedGender.value = gender;
    if (gender == 'Otro') {
      showCustomGender.value = true;
    } else {
      showCustomGender.value = false;
      customGenderController.clear();
    }
  }

  void selectLanguage(String language) {
    selectedLanguage.value = language;
  }

  void toggleInterest(int interestId) {
    if (selectedInterests.contains(interestId)) {
      selectedInterests.remove(interestId);
    } else {
      if (selectedInterests.length >= maxInterests) {
        showErrorSnackbar(
          '${_l.t('val_max_interests')} $maxInterests ${_l.t('bs_interests_selected')}',
        );
        return;
      }
      selectedInterests.add(interestId);
    }
  }

  void toggleQuality(int qualityId) {
    if (selectedQualities.contains(qualityId)) {
      selectedQualities.remove(qualityId);
    } else {
      if (selectedQualities.length >= maxQualities) {
        showErrorSnackbar(
          '${_l.t('val_max_qualities')} $maxQualities ${_l.t('bs_interests_selected')}',
        );
        return;
      }
      selectedQualities.add(qualityId);
    }
  }

  Future<void> onRegisterTap() async {
    if (dateOfBirth.value == null) {
      showErrorSnackbar(_l.t('val_dob_required'));
      return;
    }

    try {
      isLoading.value = true;

      String finalGender = selectedGender.value;
      if (selectedGender.value == 'Otro' &&
          customGenderController.text.trim().isNotEmpty) {
        finalGender = customGenderController.text.trim();
      }

      final entity = CreateUserEntity(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        dateofbirth: _formatDate(dateOfBirth.value!),
        gender: finalGender,
        bio: bioController.text.trim(),
        heightcm: heightController.text.trim(),
        primarylanguage: selectedLanguage.value,
        city: city.value.isNotEmpty ? city.value : '',
        lat: latitude.value,
        lng: longitude.value,
        interestsIds: selectedInterests.toList(),
        qualitiesIds: selectedQualities.toList(),
      );
      await createUserUsecase.execute(entity);
      await logRegisterUsecase(method: 'email');
      _clearFields();
      showSuccessSnackbar(_l.t('register_success'));
      onLoginTap();
    } catch (e) {
      print('[RegisterController] ❌ Error en registro: $e');
      showErrorSnackbar('${_l.t('error')}: ${cleanExceptionMessage(e)}');
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void onLoginTap() => Get.toNamed(RoutesNames.loginPage);

  void onNameSubmitted() => emailFocusNode.requestFocus();
  void onEmailSubmitted() => passwordFocusNode.requestFocus();
  void onPasswordSubmitted() => confirmPasswordFocusNode.requestFocus();
  void onConfirmPasswordSubmitted() => nextStep();

  void _clearFields() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    heightController.text = '170';
    cityController.clear();
    bioController.clear();
    customGenderController.clear();

    dateOfBirth.value = null;
    selectedGender.value = '';
    selectedLanguage.value = _l.deviceLanguage;
    selectedInterests.clear();
    selectedQualities.clear();
    latitude.value = '';
    longitude.value = '';
    city.value = '';
    locationObtained.value = false;
    currentStepIndex.value = 0;
    currentStep.value = RegistrationStep.basicInfo;
    bioCharCount.value = 0;
    showCustomGender.value = false;
    selectedHeight.value = 170;

    translatedInterests.clear();
    translatedQualities.clear();
  }
}
