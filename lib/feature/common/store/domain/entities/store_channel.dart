import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'code')
enum StoreChannel {
  physical('physical', '實體店面'),
  online('online', '線上店家');

  const StoreChannel(this.code, this.label);

  final String code;
  final String label;

  static const Set<StoreChannel> all = {physical, online};

  static StoreChannel? fromCode(final String? code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }

  static List<StoreChannel> listFromCodes(final Iterable<String>? codes) =>
      codes?.map(StoreChannel.fromCode).whereType<StoreChannel>().toList() ?? const [];

  static List<StoreChannel> listFromSet(final Set<StoreChannel> channels) =>
      values.where(channels.contains).toList();

  static List<String> codesFromSet(final Set<StoreChannel> channels) =>
      listFromSet(channels).map((final c) => c.code).toList();
}
