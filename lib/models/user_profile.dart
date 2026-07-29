class UserProfile {
  const UserProfile({
    required this.name,
    required this.weightKg,
    this.heightCm,
    this.gender,
  });

  final String name;
  final double weightKg;
  final double? heightCm;
  final String? gender;

  double get strideLengthMeters => heightCm != null
      ? (heightCm! * 0.415) / 100
      : 0.762;
}
