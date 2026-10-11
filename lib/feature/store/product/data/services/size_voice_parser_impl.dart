import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/body_measurement_ranges.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/product/domain/services/size_voice_parser.dart';
import 'package:typed_result/typed_result.dart';

GarmentMeasurementType? _typeFromKey(final String key) {
  for (final t in GarmentMeasurementType.values) {
    if (t.value == key) return t;
  }
  return null;
}

BodyMeasurementType? _bodyTypeFromKey(final String key) {
  for (final t in BodyMeasurementType.values) {
    if (t.value == key) return t;
  }
  return null;
}

MeasurementUnit _unitFromString(final Object? value) {
  return switch (value) {
    'cun' => MeasurementUnit.cun,
    'inch' => MeasurementUnit.inch,
    _ => MeasurementUnit.centimeter,
  };
}

double? _toDouble(final Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<ParsedSize> parseSizeVoiceResponse(final Map<String, dynamic> data) {
  final rawSizes = data['sizes'];
  if (rawSizes is! List) return [];

  final result = <ParsedSize>[];
  for (final rawSize in rawSizes) {
    if (rawSize is! Map) continue;
    final name = rawSize['name'] is String ? rawSize['name'] as String : '';
    final garmentMeasurements = <GarmentMeasurementType, ParsedMeasurement>{};
    final rawMeasurements = rawSize['garment_measurements'];
    if (rawMeasurements is Map) {
      rawMeasurements.forEach((final key, final value) {
        final type = key is String ? _typeFromKey(key) : null;
        if (type == null || value is! Map) return;
        final v = _toDouble(value['value']);
        if (v == null) return;
        garmentMeasurements[type] = ParsedMeasurement(
          value: v,
          unit: _unitFromString(value['unit']),
        );
      });
    }
    final bodyMeasurementRanges = <BodyMeasurementType, MeasurementRange>{};
    final rawRanges = rawSize['body_measurement_ranges'];
    if (rawRanges is Map) {
      rawRanges.forEach((final key, final value) {
        final type = key is String ? _bodyTypeFromKey(key) : null;
        if (type == null || value is! Map) return;
        final min = _toDouble(value['min']);
        final max = _toDouble(value['max']);
        if (min == null || max == null) return;
        bodyMeasurementRanges[type] = MeasurementRange(min: min, max: max);
      });
    }
    result.add(
      ParsedSize(
        name: name,
        garmentMeasurements: garmentMeasurements,
        bodyMeasurementRanges: bodyMeasurementRanges,
      ),
    );
  }
  return result;
}

class SizeVoiceParserImpl implements SizeVoiceParser {
  SizeVoiceParserImpl(this._supabase);

  final SupabaseClient _supabase;
  static const _timeout = Duration(seconds: 30);

  @override
  Future<Result<List<ParsedSize>, Failure>> parse({
    required final Uint8List audioBytes,
    required final String mimeType,
    required final MeasurementUnit currentUnit,
  }) async {
    try {
      final response = await _supabase.functions
          .invoke(
            AppConstants.functionParseSizeVoice,
            body: {
              'audioBase64': base64Encode(audioBytes),
              'mimeType': mimeType,
              'currentUnit': currentUnit.name,
            },
          )
          .timeout(_timeout);

      final data = response.data;
      return Ok(
        data is Map<String, dynamic> ? parseSizeVoiceResponse(data) : [],
      );
    } catch (e, stackTrace) {
      AppLogger.error('Size voice parse failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
