/// Estado del cronómetro de descanso.
/// Clase plain (sin Freezed) para no requerir build_runner.
class TimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isPaused;
  final bool isFinished;
  final bool isMinimized;

  const TimerState({
    this.totalSeconds = 180,
    this.remainingSeconds = 180,
    this.isRunning = false,
    this.isPaused = false,
    this.isFinished = false,
    this.isMinimized = false,
  });

  TimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isPaused,
    bool? isFinished,
    bool? isMinimized,
  }) {
    return TimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isFinished: isFinished ?? this.isFinished,
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerState &&
          totalSeconds == other.totalSeconds &&
          remainingSeconds == other.remainingSeconds &&
          isRunning == other.isRunning &&
          isPaused == other.isPaused &&
          isFinished == other.isFinished &&
          isMinimized == other.isMinimized;

  @override
  int get hashCode => Object.hash(
        totalSeconds,
        remainingSeconds,
        isRunning,
        isPaused,
        isFinished,
        isMinimized,
      );
}
