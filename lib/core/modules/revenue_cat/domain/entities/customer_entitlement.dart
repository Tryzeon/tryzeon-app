import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_entitlement.freezed.dart';

@freezed
sealed class CustomerEntitlement with _$CustomerEntitlement {
  const factory CustomerEntitlement({
    required final bool isProActive,
    required final String? expirationDate,
    required final String? productIdentifier,
  }) = _CustomerEntitlement;
}
