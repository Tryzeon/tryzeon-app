enum StylePreference {
  casual('casual'),
  formal('formal'),
  streetwear('streetwear'),
  minimalist('minimalist'),
  vintage('vintage'),
  boho('boho'),
  sporty('sporty'),
  elegant('elegant');

  const StylePreference(this.value);
  final String value;

  String get label => switch (this) {
    StylePreference.casual => '休閒 Casual',
    StylePreference.formal => '正式 Formal',
    StylePreference.streetwear => '街頭 Streetwear',
    StylePreference.minimalist => '極簡 Minimalist',
    StylePreference.vintage => '復古 Vintage',
    StylePreference.boho => '波西米亞 Boho',
    StylePreference.sporty => '運動 Sporty',
    StylePreference.elegant => '優雅 Elegant',
  };

  static StylePreference? tryFromString(final String value) =>
      StylePreference.values.where((final e) => e.value == value).firstOrNull;
}
