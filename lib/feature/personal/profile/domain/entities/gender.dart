enum Gender {
  female('female'),
  male('male');

  const Gender(this.value);
  final String value;

  String get label => switch (this) {
    Gender.female => '女性',
    Gender.male => '男性',
  };

  static Gender? tryFromString(final String value) =>
      Gender.values.where((final e) => e.value == value).firstOrNull;
}
