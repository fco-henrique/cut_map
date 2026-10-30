class OpeningHoursModel {
  const OpeningHoursModel({
    required this.dayOfWeek,
    required this.opensAt,
    required this.closesAt,
    this.breakStartsAt,
    this.breakEndsAt,
  });

  final int dayOfWeek;
  final String opensAt;
  final String closesAt;
  final String? breakStartsAt;
  final String? breakEndsAt;

  bool get hasBreak => breakStartsAt != null && breakEndsAt != null;

  bool get isValid {
    final time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    if (dayOfWeek < 1 ||
        dayOfWeek > 7 ||
        !time.hasMatch(opensAt) ||
        !time.hasMatch(closesAt) ||
        opensAt.compareTo(closesAt) >= 0) {
      return false;
    }
    if (breakStartsAt == null && breakEndsAt == null) return true;
    if (breakStartsAt == null || breakEndsAt == null) return false;
    return time.hasMatch(breakStartsAt!) &&
        time.hasMatch(breakEndsAt!) &&
        opensAt.compareTo(breakStartsAt!) < 0 &&
        breakStartsAt!.compareTo(breakEndsAt!) < 0 &&
        breakEndsAt!.compareTo(closesAt) < 0;
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'opensAt': opensAt,
    'closesAt': closesAt,
    if (hasBreak) 'breakStartsAt': breakStartsAt,
    if (hasBreak) 'breakEndsAt': breakEndsAt,
  };

  factory OpeningHoursModel.fromJson(Map<String, dynamic> json) =>
      OpeningHoursModel(
        dayOfWeek: json['dayOfWeek'] as int,
        opensAt: json['opensAt'] as String,
        closesAt: json['closesAt'] as String,
        breakStartsAt: json['breakStartsAt'] as String?,
        breakEndsAt: json['breakEndsAt'] as String?,
      );
}
