import 'dart:io' show HttpException;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/image_prefetch/data/services/image_prefetcher_impl.dart';
import 'package:typed_result/typed_result.dart';

class _FakeCacheManager implements BaseCacheManager {
  final _fileSystem = MemoryFileSystem();
  final List<String> fetched = [];
  final Set<String> failing = {};

  @override
  Future<File> getSingleFile(
    final String url, {
    final String? key,
    final Map<String, String>? headers,
  }) async {
    fetched.add(key ?? url);
    if (failing.contains(url)) throw const HttpException('404');
    return _fileSystem.file('cached');
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakeCacheManager cacheManager;
  late ImagePrefetcherImpl prefetcher;

  setUp(() {
    cacheManager = _FakeCacheManager();
    prefetcher = ImagePrefetcherImpl(cacheManager);
  });

  test('caches each image under its URL, once', () async {
    final result = await prefetcher.prefetch([
      'https://cdn/a.jpg',
      'https://cdn/b.jpg',
      'https://cdn/a.jpg',
    ]);

    expect(result.isSuccess, isTrue);
    expect(cacheManager.fetched, ['https://cdn/a.jpg', 'https://cdn/b.jpg']);
  });

  test('one failed image fails the prefetch but the rest still run', () async {
    cacheManager.failing.add('https://cdn/a.jpg');

    final result = await prefetcher.prefetch([
      'https://cdn/a.jpg',
      'https://cdn/b.jpg',
    ]);

    expect(result.getError(), const ServerFailure());
    expect(cacheManager.fetched, ['https://cdn/a.jpg', 'https://cdn/b.jpg']);
  });
}
