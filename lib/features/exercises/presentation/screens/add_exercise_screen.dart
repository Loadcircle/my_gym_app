import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/providers/app_config_provider.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/custom_exercises_provider.dart';

/// Pantalla para crear ejercicios personalizados.
/// Permite al usuario agregar sus propios ejercicios o maquinas.
class AddExerciseScreen extends ConsumerStatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMuscleGroup = 'Pecho';
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Muestra opciones para seleccionar imagen (camara o galeria).
  Future<void> _showImagePickerOptions() async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      builder: (context) {
        final sheetL10n = AppLocalizations.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  sheetL10n.selectImage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(sheetL10n.takePhoto),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(sheetL10n.chooseFromGallery),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    title: Text(
                      sheetL10n.removeImage,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      setState(() => _selectedImage = null);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      await _pickImage(result);
    }
  }

  /// Selecciona una imagen usando ImagePicker.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSelectingImage(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Crea el ejercicio personalizado.
  Future<void> _createExercise() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    final authState = ref.read(authStateProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mustSignInToCreateExercises),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imagePath;

      // Si hay imagen seleccionada, subirla a Storage
      if (_selectedImage != null) {
        final storageService = ref.read(storageServiceProvider);
        imagePath = await storageService.uploadUserImage(
          userId: authState.user!.uid,
          imageFile: _selectedImage!,
        );

        if (imagePath == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.errorUploadingImage),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Crear el ejercicio
      final exercise = await ref.read(customExerciseNotifierProvider.notifier).create(
        name: _nameController.text.trim(),
        muscleGroup: _selectedMuscleGroup,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        imageUrl: imagePath,
      );

      if (exercise != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exerciseCreated(exercise.name)),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, exercise);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCreatingExercise),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(l10n.newExercise),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen preview / selector
                _buildImageSelector(),
                const SizedBox(height: 24),

                // Grupo muscular
                _buildMuscleGroupSelector(),
                const SizedBox(height: 20),

                // Nombre del ejercicio
                _buildNameField(),
                const SizedBox(height: 20),

                // Notas
                _buildNotesField(),
                const SizedBox(height: 32),

                // Botones
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el selector de imagen con preview.
  Widget _buildImageSelector() {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: _isLoading ? null : _showImagePickerOptions,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppConstants.cardBorderRadius - 1,
                    ),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background.withAlpha(179),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        onPressed: _isLoading ? null : _showImagePickerOptions,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.addPhoto,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.optionalTapToSelect,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Construye el selector de grupo muscular con chips.
  Widget _buildMuscleGroupSelector() {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.muscleGroup,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.selectMuscleGroup,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MuscleGroups.all.map((group) {
            final isSelected = _selectedMuscleGroup == group;
            final color = MuscleGroups.getColor(group);
            final localizedGroup =
                MuscleGroups.getLocalizedName(group, langCode);

            return FilterChip(
              label: Text(localizedGroup),
              selected: isSelected,
              onSelected: _isLoading
                  ? null
                  : (selected) {
                      if (selected) {
                        setState(() => _selectedMuscleGroup = group);
                      }
                    },
              backgroundColor: AppColors.surfaceVariant,
              selectedColor: color.withAlpha(51),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? color : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Construye el campo de nombre del ejercicio.
  Widget _buildNameField() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exerciseName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.exerciseNameHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: l10n.exerciseNameExample,
            prefixIcon: const Icon(Icons.fitness_center),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.nameIsRequired;
            }
            if (value.trim().length < 3) {
              return l10n.nameMinLength;
            }
            if (value.trim().length > AppConstants.maxExerciseNameLength) {
              return l10n.nameTooLong;
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Construye el campo de notas.
  Widget _buildNotesField() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.personalNotes,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.personalNotesHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          enabled: !_isLoading,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.personalNotesExample,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  /// Construye los botones de accion.
  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Boton principal - Crear
        ElevatedButton(
          onPressed: _isLoading ? null : _createExercise,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
              : Text(l10n.createExercise),
        ),
        const SizedBox(height: 12),

        // Boton secundario - Cancelar
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
