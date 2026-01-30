import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/user_profile_model.dart';
import '../../providers/user_profile_provider.dart';

/// Pantalla de perfil de usuario.
/// Permite editar información personal.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  Sex? _selectedSex;

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _initializeFromProfile(UserProfileModel profile) {
    if (_isInitialized) return;
    _isInitialized = true;

    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _ageController.text = profile.age?.toString() ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _selectedSex = profile.sex;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentProfile = ref.read(userProfileProvider).valueOrNull;
      if (currentProfile == null) {
        throw Exception('No se pudo cargar el perfil');
      }

      final updated = currentProfile.copyWith(
        firstName: _firstNameController.text.trim().isEmpty
            ? null
            : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
        age: _ageController.text.isEmpty
            ? null
            : int.tryParse(_ageController.text),
        height: _heightController.text.isEmpty
            ? null
            : double.tryParse(_heightController.text),
        weight: _weightController.text.isEmpty
            ? null
            : double.tryParse(_weightController.text),
        sex: _selectedSex,
      );

      await ref.read(userProfileNotifierProvider.notifier).saveProfile(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil guardado'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar'),
            ),
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error al cargar perfil: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile != null) {
            _initializeFromProfile(profile);
          }
          return _buildForm();
        },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.defaultPadding,
          AppConstants.defaultPadding,
          AppConstants.defaultPadding,
          120, // espacio para el botón
        ),
        children: [
          // Avatar placeholder
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  _getInitials(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Nombre
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Juan',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Apellido
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Apellido',
              hintText: 'Ej: Perez',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Edad
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Edad',
              hintText: 'Ej: 25',
              prefixIcon: Icon(Icons.cake_outlined),
              suffixText: 'años',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
          ),
          const SizedBox(height: 16),

          // Altura
          TextFormField(
            controller: _heightController,
            decoration: const InputDecoration(
              labelText: 'Altura',
              hintText: 'Ej: 175',
              prefixIcon: Icon(Icons.height),
              suffixText: 'cm',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 16),

          // Peso
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Peso',
              hintText: 'Ej: 70.5',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
              suffixText: 'kg',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 16),

          // Sexo
          DropdownButtonFormField<Sex>(
            initialValue: _selectedSex,
            decoration: const InputDecoration(
              labelText: 'Sexo',
              prefixIcon: Icon(Icons.wc_outlined),
            ),
            items: [
              const DropdownMenuItem<Sex>(
                value: null,
                child: Text('Sin especificar'),
              ),
              ...Sex.values.map((sex) => DropdownMenuItem<Sex>(
                    value: sex,
                    child: Text(sex.label),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedSex = value);
            },
          ),
          const SizedBox(height: 32),

          // Nota informativa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Todos los campos son opcionales. Tu informacion se guarda de forma segura.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
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

  String _getInitials() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty && lastName.isEmpty) return '?';

    final parts = [firstName, lastName].where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
