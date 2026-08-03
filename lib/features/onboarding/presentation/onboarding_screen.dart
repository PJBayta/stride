import 'package:flutter/material.dart';

import '../../../core/legal/legal_documents.dart';
import '../../../models/user_profile.dart';
import '../../../widgets/legal_document_screen.dart';
import '../../profile/controller/profile_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController();
  String? _gender;
  var _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await profileController.completeOnboarding(
      UserProfile(
        name: _nameController.text.trim(),
        weightKg: double.parse(_weightController.text.trim()),
        heightCm: _heightController.text.trim().isEmpty
            ? null
            : double.parse(_heightController.text.trim()),
        gender: _gender,
      ),
    );
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRect(
                        child: Align(
                          widthFactor: 0.65,
                          heightFactor: 0.55,
                          child: Image.asset(
                            'assets/icon/splash_logo.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to Stride!',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A few details help make your activity estimates more personal.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      validator: _positiveNumberValidator,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Height (cm) · optional'),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? null
                          : _positiveNumberValidator(value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender · optional'),
                      items: const [
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'non_binary', child: Text('Non-binary')),
                        DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                      ],
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _isSaving ? null : _completeOnboarding,
                      child: Text(_isSaving ? 'SAVING...' : 'CONTINUE'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'By continuing, you agree to the ',
                          style: text.labelSmall,
                        ),
                        TextButton(
                          onPressed: () => _openLegalDocument(
                            LegalDocument.termsOfService,
                          ),
                          child: const Text('Terms of Service'),
                        ),
                        Text(' and ', style: text.labelSmall),
                        TextButton(
                          onPressed: () => _openLegalDocument(
                            LegalDocument.privacyPolicy,
                          ),
                          child: const Text('Privacy Policy'),
                        ),
                        Text('.', style: text.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _positiveNumberValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || parsed <= 0 ? 'Enter a value greater than 0' : null;
  }

  void _openLegalDocument(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(document: document),
      ),
    );
  }
}
