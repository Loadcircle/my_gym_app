/// Estado del cronómetro de descanso.
/// Clase plain (sin Freezed) para no requerir build_runner.
class TimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isPaused;
  final bool isFinished;

  const TimerState({
    this.totalSeconds = 120,
    this.remainingSeconds = 120,
    this.isRunning = false,
    this.isPaused = false,
    this.isFinished = false,
  });

  TimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isPaused,
    bool? isFinished,
  }) {
    return TimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isFinished: isFinished ?? this.isFinished,
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
          isFinished == other.isFinished;

  @override
  int get hashCode => Object.hash(
        totalSeconds,
        remainingSeconds,
        isRunning,
        isPaused,
        isFinished,
      );
}
