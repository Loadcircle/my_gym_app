import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/providers/app_config_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/custom_exercise_model.dart';
import '../../providers/custom_exercises_provider.dart';

/// Pantalla para editar ejercicios personalizados existentes.
class EditCustomExerciseScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const EditCustomExerciseScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<EditCustomExerciseScreen> createState() =>
      _EditCustomExerciseScreenState();
}

class _EditCustomExerciseScreenState
    extends ConsumerState<EditCustomExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMuscleGroup = 'Pecho';
  File? _selectedImage;
  String? _currentImageUrl;
  bool _removeCurrentImage = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  static const _muscleGroups = [
    'Pecho',
    'Espalda',
    'Piernas',
    'Hombros',
    'Brazos',
    'Core',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeFromExercise(CustomExerciseModel exercise) {
    if (_isInitialized) return;

    _nameController.text = exercise.name;
    _notesController.text = exercise.notes ?? '';
    _selectedMuscleGroup = exercise.muscleGroup;
    _currentImageUrl = exercise.imageUrl;
    _isInitialized = true;
  }

  Future<void> _showImagePickerOptions() async {
    final result = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      builder: (context) => SafeArea(
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
                'Cambiar imagen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Elegir de galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_selectedImage != null ||
                  (_currentImageUrl != null && !_removeCurrentImage))
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Eliminar imagen',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedImage = null;
                      _removeCurrentImage = true;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      await _pickImage(result);
    }
  }

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
          _removeCurrentImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateExercise(CustomExerciseModel currentExercise) async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesion para editar ejercicios'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? newImageUrl = currentExercise.imageUrl;
      final storageService = ref.read(storageServiceProvider);

      // Si se selecciono nueva imagen, subirla
      if (_selectedImage != null) {
        // Eliminar imagen anterior si existe
        if (currentExercise.imageUrl != null) {
          await storageService.deleteUserImage(
            userId: authState.user!.uid,
            imagePath: currentExercise.imageUrl!,
          );
        }

        // Subir nueva imagen
        newImageUrl = await storageService.uploadUserImage(
          userId: authState.user!.uid,
          imageFile: _selectedImage!,
        );

        if (newImageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al subir la imagen. Intenta de nuevo.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      } else if (_removeCurrentImage && currentExercise.imageUrl != null) {
        // Si se solicito eliminar la imagen actual
        await storageService.deleteUserImage(
          userId: authState.user!.uid,
          imagePath: currentExercise.imageUrl!,
        );
        newImageUrl = null;
      }

      // Actualizar el ejercicio
      final updatedExercise = currentExercise.copyWith(
        name: _nameController.text.trim(),
        muscleGroup: _selectedMuscleGroup,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        imageUrl: newImageUrl,
        updatedAt: DateTime.now(),
      );

      final result = await ref
          .read(customExerciseNotifierProvider.notifier)
          .update(updatedExercise);

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ejercicio "${result.name}" actualizado'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, result);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el ejercicio'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  Color _getMuscleGroupColor(String muscleGroup) {
    switch (muscleGroup) {
      case 'Pecho':
        return AppColors.muscleChest;
      case 'Espalda':
        return AppColors.muscleBack;
      case 'Piernas':
        return AppColors.muscleLegs;
      case 'Hombros':
        return AppColors.muscleShoulders;
      case 'Brazos':
        return AppColors.muscleArms;
      case 'Core':
        return AppColors.muscleCore;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseAsync =
        ref.watch(customExerciseByIdProvider(widget.exerciseId));

    return exerciseAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Error al cargar ejercicio',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      data: (exercise) {
        if (exercise == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('No encontrado')),
            body: const Center(child: Text('Ejercicio no encontrado')),
          );
        }

        _initializeFromExercise(exercise);
        return _buildContent(context, exercise);
      },
    );
  }

  Widget _buildContent(BuildContext context, CustomExerciseModel exercise) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Editar Ejercicio'),
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
                _buildImageSelector(exercise),
                const SizedBox(height: 24),
                _buildMuscleGroupSelector(),
                const SizedBox(height: 20),
                _buildNameField(),
                const SizedBox(height: 20),
                _buildNotesField(),
                const SizedBox(height: 32),
                _buildActionButtons(exercise),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector(CustomExerciseModel exercise) {
    final hasNewImage = _selectedImage != null;
    final hasCurrentImage =
        _currentImageUrl != null && !_removeCurrentImage && !hasNewImage;

    return GestureDetector(
      onTap: _isLoading ? null : _showImagePickerOptions,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: hasNewImage
            ? _buildNewImagePreview()
            : hasCurrentImage
                ? _buildCurrentImagePreview()
                : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildNewImagePreview() {
    return Stack(
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
        _buildEditImageButton(),
      ],
    );
  }

  Widget _buildCurrentImagePreview() {
    final imageUrlAsync = ref.watch(userImageUrlProvider(_currentImageUrl!));

    return imageUrlAsync.when(
      loading: () => Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(
                AppConstants.cardBorderRadius - 1,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
          _buildEditImageButton(),
        ],
      ),
      error: (error, stack) => _buildImagePlaceholder(),
      data: (imageUrl) {
        if (imageUrl == null) {
          return _buildImagePlaceholder();
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                AppConstants.cardBorderRadius - 1,
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildImagePlaceholder(),
              ),
            ),
            _buildEditImageButton(),
          ],
        );
      },
    );
  }

  Widget _buildEditImageButton() {
    return Positioned(
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
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
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
          'Agregar foto',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Opcional - Toca para seleccionar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
        ),
      ],
    );
  }

  Widget _buildMuscleGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grupo muscular',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Selecciona el grupo muscular principal',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _muscleGroups.map((group) {
            final isSelected = _selectedMuscleGroup == group;
            final color = _getMuscleGroupColor(group);

            return FilterChip(
              label: Text(group),
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

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre del ejercicio',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Nombre del ejercicio o maquina',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Ej: Press inclinado con mancuernas',
            prefixIcon: Icon(Icons.fitness_center),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es obligatorio';
            }
            if (value.trim().length < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            if (value.trim().length > AppConstants.maxExerciseNameLength) {
              return 'El nombre es muy largo';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notas personales',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Instrucciones o notas para ti (opcional)',
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
          decoration: const InputDecoration(
            hintText:
                'Ej: Bajar lento, subir explosivo.\nMantener codos a 45 grados.',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(CustomExerciseModel exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : () => _updateExercise(exercise),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
              : const Text('Guardar cambios'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
