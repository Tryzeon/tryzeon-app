enum Gender {
  female('female'),
  male('male'),
  nonBinary('non_binary'),
  undisclosed('undisclosed');

  const Gender(this.value);
  final String value;

  String get label => switch (this) {
    Gender.female => '女性',
    Gender.male => '男性',
    Gender.nonBinary => '非二元',
    Gender.undisclosed => '不願透露',
  };

  static Gender? tryFromString(final String value) =>
      Gender.values.where((final e) => e.value == value).firstOrNull;
}
