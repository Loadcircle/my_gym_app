import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/set_entry_model.dart';
import '../../providers/weight_records_provider.dart';
import 'package:flutter/services.dart';

const _uuid = Uuid();

class AdvancedWeightScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;

  const AdvancedWeightScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
  });

  @override
  ConsumerState<AdvancedWeightScreen> createState() => _AdvancedWeightScreenState();
}

class _AdvancedWeightScreenState extends ConsumerState<AdvancedWeightScreen> {
  List<_SetData> _sets = [];
  bool _isSaving = false;
  bool _didPrefill = false;
  bool _hasChanges = false;
  final _notesController = TextEditingController();
  final List<FocusNode> _weightFocusNodes = [];
  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _repsControllers = [];

  @override
  void dispose() {
    _notesController.dispose();
    for (final node in _weightFocusNodes) {
      node.dispose();
    }
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    for (final controller in _repsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sets = [_SetData(id: _uuid.v4(), weight: 0, reps: 10)];
    _initControllersForSet(0, 0, 10);

    // Pre-fill from last record after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastRecord();
    });
  }

  void _initControllersForSet(int index, double weight, int reps) {
    // Asegurar que hay suficientes controllers y focus nodes
    while (_weightFocusNodes.length <= index) {
      _weightFocusNodes.add(FocusNode());
      _weightControllers.add(TextEditingController());
      _repsControllers.add(TextEditingController());
    }
    _weightControllers[index].text = weight > 0 ? weight.toString() : '';
    _repsControllers[index].text = reps.toString();
  }

  Future<void> _loadLastRecord() async {
    if (_didPrefill) return;

    final lastRecord = await ref.read(lastWeightRecordProvider(widget.exerciseId).future);
    if (lastRecord != null && mounted) {
      setState(() {
        _didPrefill = true;

        // Pre-fill notes
        if (lastRecord.notes != null && lastRecord.notes!.isNotEmpty) {
          _notesController.text = lastRecord.notes!;
        }

        // If last record was advanced with setEntries, load all sets
        if (lastRecord.setEntries.isNotEmpty) {
          _sets = lastRecord.setEntries.map((entry) => _SetData(
            id: _uuid.v4(), // New IDs for this session
            weight: entry.weight,
            reps: entry.reps,
          )).toList();
          // Inicializar controllers para cada set cargado
          for (int i = 0; i < _sets.length; i++) {
            _initControllersForSet(i, _sets[i].weight, _sets[i].reps);
          }
        } else {
          // Quick mode - just use summary weight/reps
          _sets = [
            _SetData(
              id: _uuid.v4(),
              weight: lastRecord.weight,
              reps: lastRecord.reps,
            ),
          ];
          _initControllersForSet(0, lastRecord.weight, lastRecord.reps);
        }
      });
    }
  }

  void _addSet() {
    final last = _sets.isNotEmpty ? _sets.last : null;
    final newIndex = _sets.length;
    final newWeight = last?.weight ?? 0;
    final newReps = last?.reps ?? 10;

    setState(() {
      _hasChanges = true;
      _sets = [
        ..._sets,
        _SetData(
          id: _uuid.v4(),
          weight: newWeight,
          reps: newReps,
        ),
      ];
    });

    // Inicializar controllers para el nuevo set
    _initControllersForSet(newIndex, newWeight, newReps);

    // Focus en el campo de peso del nuevo set después del frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newIndex < _weightFocusNodes.length) {
        _weightFocusNodes[newIndex].requestFocus();
      }
    });
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _hasChanges = true;
        _sets = List.from(_sets)..removeAt(index);
      });
      // Nota: Los controllers se mantienen, solo cambia qué set usan
      // Actualizar los controllers restantes con los valores correctos
      for (int i = 0; i < _sets.length; i++) {
        _weightControllers[i].text = _sets[i].weight > 0 ? _sets[i].weight.toString() : '';
        _repsControllers[i].text = _sets[i].reps.toString();
      }
    }
  }

  void _updateWeight(int index, double weight) {
    setState(() {
      _hasChanges = true;
      final newSets = List<_SetData>.from(_sets);
      newSets[index] = newSets[index].copyWith(weight: weight);
      _sets = newSets;
    });
  }

  void _updateReps(int index, int reps) {
    setState(() {
      _hasChanges = true;
      final newSets = List<_SetData>.from(_sets);
      newSets[index] = newSets[index].copyWith(reps: reps);
      _sets = newSets;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Tienes cambios sin guardar. ¿Deseas descartarlos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  bool get _isValid => _sets.isNotEmpty && _sets.every((s) => s.weight > 0 && s.reps >= 1);

  double get _maxWeight => _sets.isEmpty ? 0 : _sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);

  int get _maxReps {
    if (_sets.isEmpty) return 0;
    final maxW = _maxWeight;
    return _sets.where((s) => s.weight == maxW).map((s) => s.reps).reduce((a, b) => a > b ? a : b);
  }

  Future<void> _save() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa peso y reps en todas las series')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final entries = _sets.asMap().entries.map((e) => SetEntryModel(
        id: e.value.id,
        setNumber: e.key + 1,
        weight: e.value.weight,
        reps: e.value.reps,
      )).toList();

      final notes = _notesController.text.trim();
      final record = await ref.read(weightRecordNotifierProvider.notifier).saveAdvancedRecord(
        exerciseId: widget.exerciseId,
        setEntries: entries,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (record != null && mounted) {
        ref.invalidate(lastWeightRecordProvider(widget.exerciseId));
        ref.invalidate(exerciseHistoryProvider(widget.exerciseId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guardado: $_maxWeight kg'), backgroundColor: Colors.green),
        );
        // Return the saved data so detail screen can update immediately
        context.pop({
          'weight': _maxWeight,
          'reps': _maxReps,
          'sets': _sets.length,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String get _formattedDate {
    final now = DateTime.now();
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          // Usar Navigator en lugar de context.pop() para evitar conflictos
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Registro Avanzado')),
        body: Column(
          children: [
            // Header con fecha (fijo)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.exerciseName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      Text(_formattedDate, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    ],
                  ),
                  Text(widget.muscleGroup, style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text('Max: $_maxWeight kg | Series: ${_sets.length}', style: TextStyle(color: AppColors.primary)),
                ],
              ),
            ),

            const Divider(height: 1),

            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lista de series
                    ...List.generate(_sets.length, (index) {
                      return _SimpleSetRow(
                        key: ValueKey(_sets[index].id),
                        index: index,
                        setData: _sets[index],
                        canDelete: _sets.length > 1,
                        weightController: index < _weightControllers.length ? _weightControllers[index] : null,
                        repsController: index < _repsControllers.length ? _repsControllers[index] : null,
                        weightFocusNode: index < _weightFocusNodes.length ? _weightFocusNodes[index] : null,
                        onWeightChanged: (v) => _updateWeight(index, v),
                        onRepsChanged: (v) => _updateReps(index, v),
                        onDelete: () => _removeSet(index),
                      );
                    }),

                    // Botón agregar serie (debajo de la lista)
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addSet,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar serie'),
                    ),

                    const SizedBox(height: 24),

                    // Campo de notas
                    Stack(
                      children: [
                        TextField(
                          controller: _notesController,
                          maxLines: 5,
                          minLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Notas (opcional)',
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) {
                            setState(() => _hasChanges = true);
                          },
                        ),
                        if (_notesController.text.isNotEmpty)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: IconButton(
                              icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                              onPressed: () {
                                setState(() {
                                  _notesController.clear();
                                  _hasChanges = true;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Botón guardar (fijo abajo)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving || !_isValid ? null : _save,
                    child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetData {
  final String id;
  final double weight;
  final int reps;
  _SetData({required this.id, required this.weight, required this.reps});
  _SetData copyWith({double? weight, int? reps}) => _SetData(id: id, weight: weight ?? this.weight, reps: reps ?? this.reps);
}

class _SimpleSetRow extends StatelessWidget {
  final int index;
  final _SetData setData;
  final bool canDelete;
  final TextEditingController? weightController;
  final TextEditingController? repsController;
  final FocusNode? weightFocusNode;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onDelete;

  const _SimpleSetRow({
    super.key,
    required this.index,
    required this.setData,
    required this.canDelete,
    this.weightController,
    this.repsController,
    this.weightFocusNode,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Número
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),

          // Peso
          Expanded(
            flex: 2,
            child: TextField(
              controller: weightController,
              focusNode: weightFocusNode,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: '0', suffixText: 'kg', isDense: true),
              onChanged: (v) => onWeightChanged(double.tryParse(v) ?? 0),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('x'),
          ),

          // Reps
          Expanded(
            flex: 2, 
            child: TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(suffixText: 'reps', isDense: true),
              onChanged: (v) => onRepsChanged(int.tryParse(v) ?? 1),
            ),
          ),

          // Delete
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.red,
              onPressed: onDelete,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
