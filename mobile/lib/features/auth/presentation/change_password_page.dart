import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/buttons.dart';
import 'auth_controller.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
            confirmNewPassword: _confirmController.text,
          );
      if (!mounted) return;
      _toast('Contraseña actualizada correctamente.', AppColors.secondary);
      context.pop();
    } on ApiException catch (error) {
      _toast(error.message, AppColors.destructive);
    } catch (_) {
      _toast('Ocurrió un error inesperado.', AppColors.destructive);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Contraseña actual',
                  controller: _currentController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.loginPassword,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nueva contraseña',
                  controller: _newController,
                  obscureText: true,
                  prefixIcon: Icons.lock_reset_outlined,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirmar nueva contraseña',
                  controller: _confirmController,
                  obscureText: true,
                  prefixIcon: Icons.lock_reset_outlined,
                  validator: (v) =>
                      Validators.confirmPassword(v, _newController.text),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La contraseña debe incluir mayúscula, minúscula, número y símbolo.',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Actualizar contraseña',
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
