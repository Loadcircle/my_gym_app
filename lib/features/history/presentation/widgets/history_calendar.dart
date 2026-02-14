import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/history_calendar_providers.dart';

/// Wrapper del TableCalendar con estilo dark theme.
class HistoryCalendar extends ConsumerWidget {
  const HistoryCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final activityDaysAsync = ref.watch(activityDaysProvider);
    final activityDays = activityDaysAsync.valueOrNull ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime.now(),
          focusedDay: selectedDay.isAfter(DateTime.now()) ? DateTime.now() : selectedDay,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: 'es_ES',
          onDaySelected: (selected, focused) {
            ref.read(selectedDayProvider.notifier).state =
                DateTime(selected.year, selected.month, selected.day);
          },
          eventLoader: (day) {
            final normalized = DateTime(day.year, day.month, day.day);
            return activityDays.contains(normalized) ? ['activity'] : [];
          },
          calendarStyle: CalendarStyle(
            // Fondo
            outsideDaysVisible: false,

            // Día seleccionado
            selectedDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),

            // Hoy
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withAlpha(51),
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),

            // Default
            defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
            weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
            disabledTextStyle: const TextStyle(color: AppColors.textDisabled),

            // Marcador de actividad (dot)
            markerDecoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            markerSize: 6,
            markersMaxCount: 1,
            markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: AppColors.textSecondary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            weekendStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
