enum AgeRange {
  age18to24('18-24'),
  age25to34('25-34'),
  age35to44('35-44'),
  age45to54('45-54'),
  age55plus('55+'),
  undisclosed('undisclosed');

  const AgeRange(this.value);
  final String value;

  String get label => switch (this) {
    AgeRange.age18to24 => '18-24',
    AgeRange.age25to34 => '25-34',
    AgeRange.age35to44 => '35-44',
    AgeRange.age45to54 => '45-54',
    AgeRange.age55plus => '55+',
    AgeRange.undisclosed => '不願透露',
  };

  static AgeRange? tryFromString(final String value) =>
      AgeRange.values.where((final e) => e.value == value).firstOrNull;
}
