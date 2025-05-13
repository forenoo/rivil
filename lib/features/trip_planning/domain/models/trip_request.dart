class TripRequest {
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? budget;
  final String? numberOfPeople;
  final List<String> preferences;

  TripRequest({
    required this.description,
    this.startDate,
    this.endDate,
    this.budget,
    this.numberOfPeople,
    this.preferences = const [],
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'budget': budget,
        'numberOfPeople': numberOfPeople,
        'preferences': preferences,
      };
}
