import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum ClothingStyle {
  basic('basic'),
  casual('casual'),
  business('business'),
  elegant('elegant'),
  sweet('sweet'),
  streetwear('streetwear'),
  sporty('sporty'),
  vintage('vintage'),
  preppy('preppy'),
  edgy('edgy'),
  natural('natural'),
  party('party'),
  homewear('homewear');

  const ClothingStyle(this.value);
  final String value;

  String get label => switch (this) {
    ClothingStyle.basic => '簡約基本',
    ClothingStyle.casual => '休閒日常',
    ClothingStyle.business => '通勤正式',
    ClothingStyle.elegant => '優雅氣質',
    ClothingStyle.sweet => '甜美可愛',
    ClothingStyle.streetwear => '街頭潮流',
    ClothingStyle.sporty => '運動機能',
    ClothingStyle.vintage => '復古',
    ClothingStyle.preppy => '學院',
    ClothingStyle.edgy => '個性酷帥',
    ClothingStyle.natural => '文青自然',
    ClothingStyle.party => '性感派對',
    ClothingStyle.homewear => '居家舒適',
  };

  static ClothingStyle? tryFromString(final String? value) =>
      ClothingStyle.values.where((final e) => e.value == value).firstOrNull;

  static List<ClothingStyle>? listFromStrings(final Iterable<String>? values) =>
      values?.map(tryFromString).whereType<ClothingStyle>().toList();

  static List<ClothingStyle> listFromSet(final Set<ClothingStyle> styles) =>
      ClothingStyle.values.where(styles.contains).toList();
}
