import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../onboarding/tour_tooltip.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
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

  /// Fecha override para guardar el registro. Si es null, usa DateTime.now().
  final DateTime? overrideDate;

  /// Showcase key opcional para el switch de modo (usado en el tour de detalle).
  final GlobalKey? showcaseModeSwitchKey;

  /// Showcase key opcional para el botón de guardar (usado en el tour de detalle).
  final GlobalKey? showcaseSaveKey;

  /// Callback para marcar el tour como visto al presionar "Omitir".
  final VoidCallback? onTourSkip;

  /// Callback cuando se agrega una nueva serie (modo avanzado).
  final VoidCallback? onSetAdded;

  const WeightInputCard({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.isCustomExercise,
    this.overrideDate,
    this.showcaseModeSwitchKey,
    this.showcaseSaveKey,
    this.onTourSkip,
    this.onSetAdded,
  });

  @override
  ConsumerState<WeightInputCard> createState() => _WeightInputCardState();
}

class _WeightInputCardState extends ConsumerState<WeightInputCard> {
  // Controllers para modo simple
  final _weightController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _notesController = TextEditingController();

  // Estado para modo avanzado
  List<SetData> _advancedSets = [SetData.create()];

  bool _isSaving = false;
  bool _hasPrefilledWeight = false;
  bool _isDirty = false;
  bool _showNotes = false;

  @override
  void dispose() {
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _notesController.dispose();
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
          _isDirty = false;
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
          _isDirty = false;
        });
      }
    } else {
      // Modo simple: usar valores resumen
      _weightController.text = lastRecord.weight.toString();
      _setsController.text = lastRecord.sets.toString();
      _repsController.text = lastRecord.reps.toString();
    }

    // Pre-llenar notas del último registro si existen
    if (lastRecord.notes != null && lastRecord.notes!.isNotEmpty) {
      _notesController.text = lastRecord.notes!;
      setState(() => _showNotes = true);
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
    final l10n = AppLocalizations.of(context);
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterWeight)),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidWeight)),
      );
      return;
    }

    final sets = int.tryParse(_setsController.text.trim()) ?? 1;
    final reps = int.tryParse(_repsController.text.trim()) ?? 1;

    setState(() => _isSaving = true);

    try {
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      final record =
          await ref.read(weightRecordNotifierProvider.notifier).saveRecord(
                exerciseId: widget.exerciseId,
                weight: weight,
                sets: sets,
                reps: reps,
                notes: notes,
                date: widget.overrideDate,
              );

      if (record != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.savedRecord(
              weight.toString(),
              sets.toString(),
              reps.toString(),
            )),
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
            content: Text(l10n.errorGeneric(e.toString())),
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
    final l10n = AppLocalizations.of(context);
    if (!_isAdvancedValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.completeAllSets)),
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

      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      final record = await ref
          .read(weightRecordNotifierProvider.notifier)
          .saveAdvancedRecord(
            exerciseId: widget.exerciseId,
            setEntries: entries,
            notes: notes,
            date: widget.overrideDate,
          );

      if (record != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.savedAdvancedRecord(
              _maxWeight.toString(),
              _advancedSets.length.toString(),
            )),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(lastWeightRecordProvider(widget.exerciseId));
        ref.invalidate(exerciseHistoryProvider(widget.exerciseId));

        // Actualizar controllers del modo simple
        _weightController.text = _maxWeight.toString();
        _setsController.text = _advancedSets.length.toString();
        _repsController.text = _maxReps.toString();

        // Regenerar IDs de las series para evitar conflicto de PK en el siguiente guardado
        setState(() {
          _advancedSets = _advancedSets
              .map((s) => SetData.create(weight: s.weight, reps: s.reps))
              .toList();
          _isDirty = false;
          _showNotes = false;
        });
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAdvanced = ref.watch(weightInputModeNotifierProvider);
    final lastRecordAsync =
        ref.watch(lastWeightRecordProvider(widget.exerciseId));

    // Prefill cuando el último registro esté disponible
    lastRecordAsync.whenData((lastRecord) {
      _prefillFromLastRecord(lastRecord, isAdvanced);
    });

    return PopScope(
      canPop: !isAdvanced || !_isDirty,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.unsavedSetsTitle),
            content: Text(l10n.unsavedSetsBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l10n.leave),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
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
                isAdvanced ? l10n.recordSets : l10n.quickRecord,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              const SizedBox(width: 8),
              _buildModeSwitch(isAdvanced, lastRecordAsync),
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

          const SizedBox(height: 12),

          // Notas opcionales
          _buildNotesSection(l10n),

          const SizedBox(height: 20),

          // Botón guardar
          _buildSaveButton(l10n, isAdvanced),
        ],
      ),
      ),
    );
  }

  Widget _buildNotesSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showNotes = !_showNotes),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showNotes ? Icons.notes : Icons.add_comment_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.personalNotes,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showNotes ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _showNotes ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.personalNotesHint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitch(
    bool isAdvanced,
    AsyncValue<dynamic> lastRecordAsync,
  ) {
    final switchWidget = SizedBox(
      height: 24,
      child: Switch(
        value: isAdvanced,
        onChanged: (value) {
          ref
              .read(weightInputModeNotifierProvider.notifier)
              .setAdvancedMode(value);
          _hasPrefilledWeight = false;
          lastRecordAsync.whenData((lastRecord) {
            _prefillFromLastRecord(lastRecord, value);
          });
        },
        activeTrackColor: AppColors.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    final key = widget.showcaseModeSwitchKey;
    if (key == null) return switchWidget;

    return tourShowcase(
      showcaseKey: key,
      title: 'Modo de registro',
      description:
          'Apagado: registra peso, series y reps de una sola vez (rápido). '
          'Encendido: registra cada serie individualmente con su peso y repeticiones.',
      height: 210,
      onSkip: widget.onTourSkip,
      child: switchWidget,
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n, bool isAdvanced) {
    final button = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isSaving ? null : (isAdvanced ? _saveAdvanced : _saveSimple),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              )
            : Text(l10n.save),
      ),
    );

    final key = widget.showcaseSaveKey;
    if (key == null) return button;

    return tourShowcase(
      showcaseKey: key,
      title: 'Guardar entrenamiento',
      description:
          'Guarda para llevar un seguimiento de tu progreso. '
          'Con 2+ registros aparece una gráfica de evolución.',
      height: 170,
      onSkip: widget.onTourSkip,
      child: button,
    );
  }

  Widget _buildSimpleContent() {
    final l10n = AppLocalizations.of(context);
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
            Text(
              l10n.kg,
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
                  Text(
                    l10n.sets,
                    style: const TextStyle(color: AppColors.textSecondary),
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
                  Text(
                    l10n.reps,
                    style: const TextStyle(color: AppColors.textSecondary),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen
        if (_advancedSets.isNotEmpty && _maxWeight > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.advancedSummary(
                _maxWeight.toString(),
                _advancedSets.length.toString(),
              ),
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
              _isDirty = true;
            });
          },
          onSetAdded: widget.onSetAdded,
        ),
      ],
    );
  }
}
