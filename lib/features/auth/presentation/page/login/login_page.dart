import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/auth/presentation/page/login/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({Key? key}) : super(key: key);

  LanguageController get lang => Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/fondo.png', fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  color: const Color.fromARGB(255, 93, 93, 93).withOpacity(0.6),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: ThemeColor.paddingLarge,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    SizedBox(height: ThemeColor.paddingExtraLarge * 2),
                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset('assets/logo/logo.png', width: 250, height: 100),
        ),
        SizedBox(height: ThemeColor.paddingLarge),
        Text(
          lang.t('login_title'),
          style: ThemeColor.headingLarge.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: ThemeColor.textDarkColor,
          ),
        ),
        SizedBox(height: ThemeColor.paddingSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lang.t('login_no_account'),
              style: ThemeColor.bodyMedium.copyWith(
                color: ThemeColor.textDarkColor,
              ),
            ),
            GestureDetector(
              onTap: controller.onRegisterTap,
              child: Text(
                lang.t('login_register'),
                style: ThemeColor.bodyMedium.copyWith(
                  color: ThemeColor.primaryColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: ThemeColor.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemeColor.createLabeledTextField(
            label: lang.t('login_email'),
            controller: controller.emailController,
            focusNode: controller.emailFocusNode,
            hintText: lang.t('login_email_hint'),
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => controller.onemailSubmitted(),
          ),

          SizedBox(height: ThemeColor.paddingLarge),

          Obx(
            () => ThemeColor.createLabeledTextField(
              label: lang.t('login_password'),
              controller: controller.passwordController,
              focusNode: controller.passwordFocusNode,
              hintText: '••••••••••',
              obscureText: !controller.showPassword.value,
              onSubmitted: (_) => controller.onPasswordSubmitted(),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.showPassword.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: ThemeColor.textSecondaryColor,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
          ),

          SizedBox(height: ThemeColor.paddingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () async {
                final email = await Get.toNamed(RoutesNames.forgotPasswordPage, arguments: {'email': controller.emailController.text.trim()});
                if (email is String) {
                  controller.emailController.text = email;
                  controller.passwordController.clear();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  lang.t('login_forgot'),
                  style: ThemeColor.bodyMedium.copyWith(
                    color: ThemeColor.primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: ThemeColor.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: ThemeColor.paddingSmall),
          _buildRememberMeCheckbox(),
          SizedBox(height: ThemeColor.paddingExtraLarge),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Text(
          lang.t('login_remember'),
          style: ThemeColor.bodyMedium.copyWith(
            color: ThemeColor.textSecondaryColor,
          ),
        ),
        SizedBox(width: ThemeColor.paddingSmall),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: ThemeColor.primaryColor,
            borderRadius: ThemeColor.smallBorderRadius,
          ),
          child: Icon(Icons.check, color: ThemeColor.textLightColor, size: 16),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.onLoginTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeColor.tertiaryColor,
            foregroundColor: ThemeColor.textLightColor,
            disabledBackgroundColor: ThemeColor.primaryColor.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: ThemeColor.circularBorderRadius,
            ),
            elevation: ThemeColor.elevationSmall,
            shadowColor: ThemeColor.shadowColor,
          ),
          child: controller.isLoading.value
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeColor.textLightColor,
                    ),
                  ),
                )
              : Text(
                  lang.t('login_btn'),
                  style: ThemeColor.buttonText.copyWith(fontSize: 16),
                ),
        ),
      ),
    );
  }
}