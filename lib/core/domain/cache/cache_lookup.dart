sealed class CacheLookup<T> {
  const CacheLookup();
}

final class CacheMiss<T> extends CacheLookup<T> {
  const CacheMiss();
}

final class CacheHit<T> extends CacheLookup<T> {
  const CacheHit(this.data);

  final T data;
}

final class CacheEmpty<T> extends CacheLookup<T> {
  const CacheEmpty();
}
