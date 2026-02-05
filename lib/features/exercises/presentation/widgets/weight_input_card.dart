import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/set_entry_model.dart';
import '../../data/models/weight_record_model.dart';
import '../../providers/user_preferences_provider.dart';
import '../../providers/weight_records_provider.dart';
import 'advanced_sets_input.dart';

/// Widget unificado para registrar peso con toggle entre modo simple y avanzado.
class WeightInputCard extends ConsumerStatefulWidget {
  /// ID del ejercicio (para custom exercises debe incluir prefijo 'custom_').
  final String exerciseId;

  /// Nombre del ejercicio (para mostrar en mensajes).
  final String exerciseName;

  /// Grupo muscular del ejercicio.
  final String muscleGroup;

  /// Si es un ejercicio personalizado.
  final bool isCustomExercise;

  const WeightInputCard({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.isCustomExercise,
  });

  @override
  ConsumerState<WeightInputCard> createState() => _WeightInputCardState();
}

class _WeightInputCardState extends ConsumerState<WeightInputCard> {
  // Controllers para modo simple
  final _weightController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');

  // Estado para modo avanzado
  List<SetData> _advancedSets = [SetData.create()];

  bool _isSaving = false;
  bool _hasPrefilledWeight = false;

  @override
  void dispose() {
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _prefillFromLastRecord(WeightRecordModel? lastRecord, bool isAdvanced) {
    if (_hasPrefilledWeight || lastRecord == null) return;

    _hasPrefilledWeight = true;

    if (isAdvanced) {
      // Modo avanzado: cargar series
      if (lastRecord.setEntries.isNotEmpty) {
        setState(() {
          _advancedSets = lastRecord.setEntries
              .map((entry) => SetData.create(
                    weight: entry.weight,
                    reps: entry.reps,
                  ))
              .toList();
        });
      } else {
        // Último registro era simple, crear una serie con esos valores
        setState(() {
          _advancedSets = [
            SetData.create(
              weight: lastRecord.weight,
              reps: lastRecord.reps,
            ),
          ];
        });
      }
    } else {
      // Modo simple: usar valores resumen
      _weightController.text = lastRecord.weight.toString();
      _setsController.text = lastRecord.sets.toString();
      _repsController.text = lastRecord.reps.toString();
    }
  }

  double get _maxWeight {
    if (_advancedSets.isEmpty) return 0;
    return _advancedSets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  int get _maxReps {
    if (_advancedSets.isEmpty) return 0;
    final maxW = _maxWeight;
    return _advancedSets
        .where((s) => s.weight == maxW)
        .map((s) => s.reps)
        .reduce((a, b) => a > b ? a : b);
  }

  bool get _isAdvancedValid {
    return _advancedSets.isNotEmpty &&
        _advancedSets.every((s) => s.weight > 0 && s.reps >= 1);
  }

  Future<void> _saveSimple() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el peso')),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso invalido')),
      );
      return;
    }

    final sets = int.tryParse(_setsController.text.trim()) ?? 1;
    final reps = int.tryParse(_repsController.text.trim()) ?? 1;

    setState(() => _isSaving = true);

    try {
      final record =
          await ref.read(weightRecordNotifierProvider.notifier).saveRecord(
                exerciseId: widget.exerciseId,
                weight: weight,
                sets: sets,
                reps: reps,
              );

      if (record != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guardado: $weight kg x $sets series x $reps reps'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(lastWeightRecordProvider(widget.exerciseId));
        ref.invalidate(exerciseHistoryProvider(widget.exerciseId));
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
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveAdvanced() async {
    if (!_isAdvancedValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Completa peso y reps en todas las series')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final entries = _advancedSets.asMap().entries.map((e) {
        return SetEntryModel(
          id: e.value.id,
          setNumber: e.key + 1,
          weight: e.value.weight,
          reps: e.value.reps,
        );
      }).toList();

      final record = await ref
          .read(weightRecordNotifierProvider.notifier)
          .saveAdvancedRecord(
            exerciseId: widget.exerciseId,
            setEntries: entries,
          );

      if (record != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Guardado: $_maxWeight kg (${_advancedSets.length} series)'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(lastWeightRecordProvider(widget.exerciseId));
        ref.invalidate(exerciseHistoryProvider(widget.exerciseId));

        // Actualizar también los controllers del modo simple
        _weightController.text = _maxWeight.toString();
        _setsController.text = _advancedSets.length.toString();
        _repsController.text = _maxReps.toString();
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdvanced = ref.watch(weightInputModeNotifierProvider);
    final lastRecordAsync =
        ref.watch(lastWeightRecordProvider(widget.exerciseId));

    // Prefill cuando el último registro esté disponible
    lastRecordAsync.whenData((lastRecord) {
      _prefillFromLastRecord(lastRecord, isAdvanced);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y switch
          Row(
            children: [
              Text(
                isAdvanced ? 'Registrar series' : 'Registro rápido',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              const SizedBox(width: 8),
              SizedBox(
                height: 24,
                child: Switch(
                  value: isAdvanced,
                  onChanged: (value) {
                    ref
                        .read(weightInputModeNotifierProvider.notifier)
                        .setAdvancedMode(value);
                    // Resetear prefill flag para que se actualice con el nuevo modo
                    _hasPrefilledWeight = false;
                    // Forzar re-prefill
                    lastRecordAsync.whenData((lastRecord) {
                      _prefillFromLastRecord(lastRecord, value);
                    });
                  },
                  activeTrackColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contenido según modo
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isAdvanced
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildSimpleContent(),
            secondChild: _buildAdvancedContent(),
          ),

          const SizedBox(height: 20),

          // Botón guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : (isAdvanced ? _saveAdvanced : _saveSimple),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleContent() {
    return Column(
      children: [
        // Campo de peso grande
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTextStyles.weightValue,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '0',
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const Text(
              'kg',
              style: AppTextStyles.weightUnit,
            ),
          ],
        ),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 16),

        // Series y repeticiones
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Series',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Reps',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen
        if (_advancedSets.isNotEmpty && _maxWeight > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Max: $_maxWeight kg | Series: ${_advancedSets.length}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Input de series
        AdvancedSetsInput(
          initialSets: _advancedSets,
          onSetsChanged: (sets) {
            setState(() {
              _advancedSets = sets;
            });
          },
        ),
      ],
    );
  }
}
