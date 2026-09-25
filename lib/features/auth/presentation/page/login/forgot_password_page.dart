import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';

/// Recuperar contraseña en dos pasos: 1) correo → recibe un código, 2) código + contraseña nueva.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  bool _showPassword = false;

  LanguageController get _l => Get.find<LanguageController>();

  @override
  void initState() {
    super.initState();
    final prefill = Get.arguments is Map ? Get.arguments['email'] : null;
    if (prefill is String) _email.text = prefill;
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final r = await http.post(
      Uri.parse('${AppConstants.serverBase}/Auth/$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode != 200) throw Exception(data is Map ? (data['message'] ?? 'Error') : 'Error');
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!GetUtils.isEmail(email)) return showErrorSnackbarGetx(_l.t('forgot_err_email'));

    setState(() => _loading = true);
    try {
      await _post('olvide-password', {'email': email});
      if (!mounted) return;
      setState(() => _codeSent = true);
      showSuccessSnackbarGetx(_l.t('forgot_code_sent'));
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().length != 6) return showErrorSnackbarGetx(_l.t('forgot_err_code'));
    if (_password.text.length < 8) return showErrorSnackbarGetx(_l.t('forgot_err_password'));

    setState(() => _loading = true);
    try {
      await _post('restablecer-password', {
        'email': _email.text.trim(),
        'codigo': _code.text.trim(),
        'nuevaPassword': _password.text,
      });
      showSuccessSnackbarGetx(_l.t('forgot_done'));
      Get.back(result: _email.text.trim());
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/fondo.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: const Color.fromARGB(255, 93, 93, 93).withValues(alpha: 0.6))),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                    onPressed: Get.back,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: ThemeColor.paddingLarge),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _l.t('forgot_title'),
                              style: ThemeColor.headingLarge.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: ThemeColor.textDarkColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _codeSent ? _l.t('forgot_step2') : _l.t('forgot_step1'),
                              style: ThemeColor.bodyMedium.copyWith(color: ThemeColor.textDarkColor),
                            ),
                            const SizedBox(height: 28),
                            ThemeColor.createLabeledTextField(
                              label: _l.t('login_email'),
                              controller: _email,
                              hintText: _l.t('login_email_hint'),
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_codeSent && !_loading,
                            ),
                            if (_codeSent) ...[
                              const SizedBox(height: 16),
                              ThemeColor.createLabeledTextField(
                                label: _l.t('forgot_code'),
                                controller: _code,
                                hintText: '••••••',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              ThemeColor.createLabeledTextField(
                                label: _l.t('forgot_new_password'),
                                controller: _password,
                                hintText: '••••••••••',
                                obscureText: !_showPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: ThemeColor.textSecondaryColor,
                                  ),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : (_codeSent ? _reset : _sendCode),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ThemeColor.tertiaryColor,
                                  foregroundColor: ThemeColor.textLightColor,
                                  disabledBackgroundColor: ThemeColor.primaryColor.withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(borderRadius: ThemeColor.circularBorderRadius),
                                ),
                                child: _loading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(ThemeColor.textLightColor),
                                        ),
                                      )
                                    : Text(
                                        _codeSent ? _l.t('forgot_change_btn') : _l.t('forgot_send_btn'),
                                        style: ThemeColor.buttonText.copyWith(fontSize: 16),
                                      ),
                              ),
                            ),
                            if (_codeSent)
                              Center(
                                child: TextButton(
                                  onPressed: _loading ? null : _sendCode,
                                  child: Text(
                                    _l.t('forgot_resend'),
                                    style: ThemeColor.bodyMedium.copyWith(
                                      color: ThemeColor.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
