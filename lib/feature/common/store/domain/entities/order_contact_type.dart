import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'code')
enum OrderContactType {
  line('line', 'LINE'),
  facebook('facebook', 'Facebook'),
  instagram('instagram', 'Instagram');

  const OrderContactType(this.code, this.label);

  final String code;
  final String label;

  static OrderContactType? fromCode(final String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}
