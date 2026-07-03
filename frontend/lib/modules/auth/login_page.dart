import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import 'auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthController _authController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final Worker _lastUsernameWorker;
  late final Worker _sessionWorker;
  bool _usernameEdited = false;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _usernameController = TextEditingController(
      text: _authController.lastUsername.value,
    );
    _passwordController = TextEditingController();

    _lastUsernameWorker = ever<String>(_authController.lastUsername, (value) {
      if (!_usernameEdited) {
        _usernameController.text = value;
      }
    });
    _sessionWorker = ever(_authController.session, (session) {
      if (session != null && mounted) {
        Get.offAllNamed(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _lastUsernameWorker.dispose();
    _sessionWorker.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await _authController.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      rememberLogin: _authController.rememberLogin.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '千树DMS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '登录系统',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    key: const ValueKey('login-username-field'),
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    onChanged: (_) {
                      _usernameEdited = true;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('login-password-field'),
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    obscureText: true,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Material(
                      type: MaterialType.transparency,
                      child: CheckboxListTile(
                        key: const ValueKey('login-remember-checkbox'),
                        value: _authController.rememberLogin.value,
                        onChanged: (value) {
                          _authController.rememberLogin.value = value ?? false;
                        },
                        title: const Text('记住登录'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Obx(() {
                    final message = _authController.errorMessage.value;
                    if (message.isEmpty) {
                      return const SizedBox(height: 8);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        message,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    );
                  }),
                  Obx(
                    () => FilledButton(
                      key: const ValueKey('login-submit-button'),
                      onPressed: _authController.isLoading.value
                          ? null
                          : _submit,
                      child: Text(
                        _authController.isLoading.value ? '登录中...' : '登录',
                      ),
                    ),
                  ),
                  Obx(() {
                    if (!_authController.isRestoring.value) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        '正在恢复登录状态...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
