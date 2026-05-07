/// Backward-compatible barrel file. The original 1,316-line implementation
/// has been split into:
///   - `multi_schedule_form.dart` (+ `multi_schedule_form_builders.dart` part)
///   - `schedule_form.dart`       (+ `schedule_form_builders.dart` part)
///
/// All previous symbols (`MultiScheduleForm`, `MultiScheduleFormState`,
/// `ScheduleForm`, `ScheduleFormState`) remain importable from here, so
/// existing call sites do not need to change.
library;

export 'multi_schedule_form.dart';
export 'schedule_form.dart';
