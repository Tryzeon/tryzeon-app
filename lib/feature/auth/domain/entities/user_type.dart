enum UserType {
  personal('personal'),
  store('store');

  const UserType(this.value);
  final String value;

  static UserType? tryFromString(final String? value) =>
      UserType.values.where((final e) => e.value == value).firstOrNull;
}
