class DayOffDTO {
  final DateTime date;
  final String? reason;

  const DayOffDTO({required this.date, this.reason});

  factory DayOffDTO.fromJson(Map<String, dynamic> json) {
    return DayOffDTO(
      date: DateTime.parse(json['date'] as String),
      reason: json['reason'] as String?,
    );
  }
}
