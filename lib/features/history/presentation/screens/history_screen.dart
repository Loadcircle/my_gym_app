import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../exercises/providers/weight_records_provider.dart';
import '../../../routines/providers/routine_completion_status_provider.dart';
import '../../providers/history_calendar_providers.dart';
import '../widgets/day_detail_panel.dart';
import '../widgets/history_calendar.dart';
import '../widgets/history_v2_skeleton.dart';
import '../widgets/last_workout_card.dart';
import '../widgets/quick_date_chips.dart';

/// Pantalla de historial v2 con calendario.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Set initial selected day to last workout day once data loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSelectedDay();
    });
  }

  void _initSelectedDay() {
    final lastDayAsync = ref.read(lastWorkoutDayProvider);
    lastDayAsync.whenData((lastDay) {
      if (!_initialized && lastDay != null && mounted) {
        _initialized = true;
        ref.read(selectedDayProvider.notifier).state = lastDay;
      }
    });
  }

  Future<void> _onRefresh() async {
    ref.invalidate(allHistoryProvider);
    ref.invalidate(routineCompletionsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    _initialized = false;
    _initSelectedDay();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(combinedHistoryProvider);

    // Listen for first data load to set initial selected day
    ref.listen(lastWorkoutDayProvider, (prev, next) {
      if (!_initialized) {
        _initSelectedDay();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menu',
        ),
        title: const Text('Historial'),
      ),
      body: historyAsync.when(
        loading: () => const HistoryV2Skeleton(),
        error: (error, stack) => _buildErrorState(context, error),
        data: (_) => RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.cardBackground,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LastWorkoutCard(),
                HistoryCalendar(),
                QuickDateChips(),
                DayDetailPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar historial',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(allHistoryProvider);
              ref.invalidate(routineCompletionsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
