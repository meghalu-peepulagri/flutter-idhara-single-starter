/// Response body for POST /motor-schedules/bulk/republish.
///
/// The endpoint always returns HTTP 200 inside the standard envelope:
///   { "status": 200, "success": true, "message": "...",
///     "data": { "republished": [...], "skipped": [...], "failed": [...] } }
///
/// Per-item buckets live under `data`:
///   • republished → pushed to the device and ACKed
///   • skipped     → not PENDING or had no starter (nothing to send)
///   • failed      → MQTT publish failed / device offline
class ScheduleRepublishResult {
  final bool success;
  final String? message;
  final List<int> republished;
  final List<int> skipped;
  final List<int> failed;
  final int? chunks;
  final int? acked;

  const ScheduleRepublishResult({
    this.success = false,
    this.message,
    this.republished = const [],
    this.skipped = const [],
    this.failed = const [],
    this.chunks,
    this.acked,
  });

  factory ScheduleRepublishResult.fromJson(Map<String, dynamic> json) {
    List<int> toIntList(dynamic v) => v is List
        ? v.map((e) => int.tryParse('$e') ?? 0).where((e) => e > 0).toList()
        : <int>[];
    // Buckets are nested under `data`; tolerate either shape.
    final data = json['data'];
    final map = data is Map<String, dynamic> ? data : json;
    return ScheduleRepublishResult(
      success: json['success'] == true,
      message: json['message'] as String?,
      republished: toIntList(map['republished']),
      skipped: toIntList(map['skipped']),
      failed: toIntList(map['failed']),
      chunks: map['chunks'] is int ? map['chunks'] as int : null,
      acked: map['acked'] is int ? map['acked'] as int : null,
    );
  }

  /// True when the device accepted at least one of the requested schedules.
  bool get hasRepublished => republished.isNotEmpty;

  /// True when at least one schedule couldn't be pushed — the backend puts
  /// device-offline / MQTT-publish failures in this bucket.
  bool get hasFailed => failed.isNotEmpty;

  /// True when the backend couldn't reach the device. Covers both response
  /// shapes: the bucketed form (rows in `failed`, none republished) and the
  /// newer counter form (`data.acked == 0`, nothing acknowledged).
  bool get isDeviceOffline =>
      !hasRepublished && (hasFailed || (acked != null && acked! <= 0));
}
