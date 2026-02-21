import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:controlzukis/features/onboarding/domain/models/business_type.dart';
import 'package:controlzukis/features/onboarding/domain/models/onboarding_input.dart';
import 'package:controlzukis/features/bootstrap/presentation/controllers/bootstrap_controller.dart';
import 'package:controlzukis/features/onboarding/presentation/controllers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _branchCtrl = TextEditingController(text: 'Casa Central');
  final _adminCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  BusinessType _businessType = BusinessType.ferreteria;
  bool _isSubmitting = false;
  Object? _submitError;

  @override
  void dispose() {
    _companyCtrl.dispose();
    _branchCtrl.dispose();
    _adminCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar empresa')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextFormField(
                      controller: _companyCtrl,
                      decoration: const InputDecoration(labelText: 'Empresa'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BusinessType>(
                      initialValue: _businessType,
                      decoration: const InputDecoration(labelText: 'Rubro'),
                      items: BusinessType.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _businessType = v ?? _businessType),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre admin',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email admin',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Clave admin',
                      ),
                      validator: (v) => (v == null || v.trim().length < 4)
                          ? 'Mínimo 4 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _branchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sucursal inicial',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final router = GoRouter.of(context);
                              setState(() {
                                _isSubmitting = true;
                                _submitError = null;
                              });
                              try {
                                await ref
                                    .read(onboardingControllerProvider)
                                    .submit(
                                      OnboardingInput(
                                        companyName: _companyCtrl.text.trim(),
                                        branchName: _branchCtrl.text.trim(),
                                        adminName: _adminCtrl.text.trim(),
                                        adminEmail: _emailCtrl.text.trim(),
                                        adminPassword: _passwordCtrl.text
                                            .trim(),
                                        businessType: _businessType,
                                      ),
                                    );
                                if (!mounted) return;
                                ref.invalidate(bootstrapControllerProvider);
                                router.go('/splash');
                              } catch (e) {
                                setState(() {
                                  _submitError = e;
                                });
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              }
                            },
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Finalizar onboarding'),
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Error: $_submitError',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
