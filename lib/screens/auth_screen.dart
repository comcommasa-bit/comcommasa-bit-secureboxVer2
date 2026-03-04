/// 認証画面
///
/// アプリ起動時に表示される画面。
/// 初回起動時: マスターパスワードの設定を行う。
/// 2回目以降: マスターパスワードまたは生体認証でログインを行う。
library;

import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/toast.dart';
import 'list_screen.dart';

/// 認証画面ウィジェット
class AuthScreen extends StatefulWidget {
  /// [AuthScreen] を作成する
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _isInitialized = false;
  bool _isRegistering = false;
  bool _isLoading = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final hasPassword = await _authService.isPasswordSet;
    final canBiometrics = await _authService.isBiometricsAvailable;
    final isBiometricsEnabled = await _authService.isBiometricsEnabled;

    if (mounted) {
      setState(() {
        _isRegistering = !hasPassword;
        _canCheckBiometrics = canBiometrics;
        _isInitialized = true;
      });

      // ログインモードかつ生体認証が有効なら自動で認証開始
      if (!_isRegistering && isBiometricsEnabled && canBiometrics) {
        _authenticateBiometrics();
      }
    }
  }

  Future<void> _authenticateBiometrics() async {
    final authenticated = await _authService.authenticateBiometric();
    if (authenticated && mounted) {
      _navigateToHome();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final password = _passwordController.text;

      if (_isRegistering) {
        // 初回登録
        await _authService.savePassword(password);
        if (_canCheckBiometrics) {
          await _authService.setBiometricsEnabled(true);
        }
        if (mounted) {
          AppToast.showSuccess(context, 'マスターパスワードを設定しました');
          _navigateToHome();
        }
      } else {
        // ログイン
        final isValid = await _authService.verifyPassword(password);
        if (isValid) {
          if (mounted) _navigateToHome();
        } else {
          if (mounted) {
            AppToast.showError(context, 'パスワードが間違っています');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'エラーが発生しました');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ListScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  _isRegistering ? '初期設定' : 'ログイン',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegistering
                      ? 'マスターパスワードを設定してください。\n'
                          'このパスワードは復元できません。'
                      : 'マスターパスワードを入力してロック解除',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'マスターパスワード',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  obscureText: true,
                  validator: Validators.masterPassword,
                  onFieldSubmitted: (_) =>
                      _isRegistering ? null : _submit(),
                ),
                // 初回設定時のみ確認入力を表示
                if (_isRegistering) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    decoration: const InputDecoration(
                      labelText: 'パスワード確認',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'パスワードが一致しません';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isRegistering ? '設定して開始' : 'ロック解除',
                          ),
                  ),
                ),
                if (!_isRegistering && _canCheckBiometrics) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _authenticateBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('生体認証を使用'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
