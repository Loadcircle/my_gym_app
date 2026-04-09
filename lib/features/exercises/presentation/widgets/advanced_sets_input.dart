import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

const _uuid = Uuid();

/// Datos de una serie individual.
class SetData {
  final String id;
  final double? weight; // null = campo vacío (no válido), 0.0 = explícitamente cero
  final int reps;

  SetData({
    required this.id,
    required this.weight,
    required this.reps,
  });

  SetData copyWith({int? reps}) => SetData(
        id: id,
        weight: weight,
        reps: reps ?? this.reps,
      );

  SetData withWeight(double? w) => SetData(id: id, weight: w, reps: reps);

  /// Crea un nuevo SetData con ID único.
  factory SetData.create({double? weight, int reps = 0}) {
    return SetData(id: _uuid.v4(), weight: weight, reps: reps);
  }
}

/// Widget para ingresar múltiples series con peso y repeticiones.
class AdvancedSetsInput extends StatefulWidget {
  /// Lista inicial de series.
  final List<SetData> initialSets;

  /// Callback cuando cambian las series.
  final ValueChanged<List<SetData>> onSetsChanged;

  /// Callback cuando se agrega una nueva serie.
  final VoidCallback? onSetAdded;

  const AdvancedSetsInput({
    super.key,
    required this.initialSets,
    required this.onSetsChanged,
    this.onSetAdded,
  });

  @override
  State<AdvancedSetsInput> createState() => _AdvancedSetsInputState();
}

class _AdvancedSetsInputState extends State<AdvancedSetsInput> {
  late List<SetData> _sets;
  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _repsControllers = [];
  final List<FocusNode> _weightFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _sets = List.from(widget.initialSets);
    if (_sets.isEmpty) {
      _sets = [SetData.create()];
    }
    for (int i = 0; i < _sets.length; i++) {
      _initControllersForSet(i, _sets[i].weight, _sets[i].reps);
    }
  }

  @override
  void didUpdateWidget(AdvancedSetsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualizar si los IDs de las series cambiaron (carga externa, no edición del usuario)
    if (widget.initialSets != oldWidget.initialSets &&
        widget.initialSets.isNotEmpty) {
      final oldIds = oldWidget.initialSets.map((s) => s.id).toSet();
      final newIds = widget.initialSets.map((s) => s.id).toSet();

      // Solo sincronizar si hay series nuevas o eliminadas externamente
      if (!_setsEqual(oldIds, newIds)) {
        _sets = List.from(widget.initialSets);
        // Limpiar controllers extra si hay menos series
        while (_weightControllers.length > _sets.length) {
          _weightControllers.removeLast().dispose();
          _repsControllers.removeLast().dispose();
          _weightFocusNodes.removeLast().dispose();
        }
        // Actualizar controllers
        for (int i = 0; i < _sets.length; i++) {
          _initControllersForSet(i, _sets[i].weight, _sets[i].reps);
        }
        setState(() {});

      }
    }
  }

  bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  void dispose() {
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    for (final controller in _repsControllers) {
      controller.dispose();
    }
    for (final node in _weightFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _initControllersForSet(int index, double? weight, int reps) {
    while (_weightControllers.length <= index) {
      _weightControllers.add(TextEditingController());
      _repsControllers.add(TextEditingController());
      _weightFocusNodes.add(FocusNode());
    }
    // Formatear peso sin decimales innecesarios (60.0 → "60", 60.5 → "60.5")
    _weightControllers[index].text = weight != null ? _formatWeight(weight) : '';
    _repsControllers[index].text = reps > 0 ? reps.toString() : '';
  }

  String _formatWeight(double weight) {
    if (weight == weight.truncateToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toString();
  }

  void _addSet() {
    final last = _sets.isNotEmpty ? _sets.last : null;
    final newIndex = _sets.length;
    final newWeight = last?.weight; // null si el último set estaba vacío
    final newReps = 0;

    setState(() {
      _sets = [
        ..._sets,
        SetData.create(weight: newWeight, reps: newReps),
      ];
    });

    _initControllersForSet(newIndex, newWeight, newReps);
    widget.onSetsChanged(_sets);
    widget.onSetAdded?.call();

    // Focus en el campo de peso del nuevo set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newIndex < _weightFocusNodes.length) {
        _weightFocusNodes[newIndex].requestFocus();
      }
    });
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _sets = List.from(_sets)..removeAt(index);
      });
      // Actualizar controllers restantes
      for (int i = 0; i < _sets.length; i++) {
        _weightControllers[i].text =
            _sets[i].weight != null ? _formatWeight(_sets[i].weight!) : '';
        _repsControllers[i].text = _sets[i].reps.toString();
      }
      widget.onSetsChanged(_sets);
    }
  }

  void _updateWeight(int index, double? weight) {
    setState(() {
      final newSets = List<SetData>.from(_sets);
      newSets[index] = newSets[index].withWeight(weight);
      _sets = newSets;
    });
    widget.onSetsChanged(_sets);
  }

  void _updateReps(int index, int reps) {
    setState(() {
      final newSets = List<SetData>.from(_sets);
      newSets[index] = newSets[index].copyWith(reps: reps);
      _sets = newSets;
    });
    widget.onSetsChanged(_sets);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lista de series
        ...List.generate(_sets.length, (index) {
          return _SetRow(
            key: ValueKey(_sets[index].id),
            index: index,
            setData: _sets[index],
            canDelete: _sets.length > 1,
            weightController:
                index < _weightControllers.length ? _weightControllers[index] : null,
            repsController:
                index < _repsControllers.length ? _repsControllers[index] : null,
            weightFocusNode:
                index < _weightFocusNodes.length ? _weightFocusNodes[index] : null,
            onWeightChanged: (v) => _updateWeight(index, v), // double?
            onRepsChanged: (v) => _updateReps(index, v),
            onDelete: () => _removeSet(index),
          );
        }),

        // Botón agregar serie
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addSet,
          icon: const Icon(Icons.add, size: 18),
          label: Text(AppLocalizations.of(context).addSet),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withAlpha(128)),
          ),
        ),
      ],
    );
  }
}

/// Fila individual para una serie.
class _SetRow extends StatelessWidget {
  final int index;
  final SetData setData;
  final bool canDelete;
  final TextEditingController? weightController;
  final TextEditingController? repsController;
  final FocusNode? weightFocusNode;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onDelete;

  const _SetRow({
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
          // Número de serie
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Peso
          Expanded(
            flex: 2,
            child: TextField(
              controller: weightController,
              focusNode: weightFocusNode,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                LengthLimitingTextInputFormatter(6),
              ],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'kg',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              onChanged: (v) => onWeightChanged(v.isEmpty ? null : double.tryParse(v)),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('x', style: TextStyle(color: AppColors.textSecondary)),
          ),

          // Repeticiones
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
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                suffixText: 'reps',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              onChanged: (v) => onRepsChanged(int.tryParse(v) ?? 1),
            ),
          ),

          // Botón eliminar
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onDelete,
            )
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }
}
