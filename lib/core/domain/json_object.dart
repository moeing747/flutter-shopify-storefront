/// Thrown when a response does not have the shape the mapper expects.
/// Carries the JSON path so the log says where the contract broke.
class MalformedResponse implements Exception {
  const MalformedResponse(this.path, this.expected, this.actual);

  final String path;
  final String expected;
  final Object? actual;

  @override
  String toString() =>
      'Malformed response at $path: expected $expected, '
      'got ${actual == null ? 'null' : actual.runtimeType}';
}

/// Typed, path-aware view over a decoded JSON object. Mappers read fields
/// through it so a malformed response fails with a [MalformedResponse] that
/// names the field, instead of a type-cast error somewhere in the mapper.
class JsonObject {
  const JsonObject(this._map, [this._path = r'$']);

  final Map<String, dynamic> _map;
  final String _path;

  Map<String, dynamic> get raw => _map;

  String string(String key) => _read<String>(key, 'String');

  String? stringOrNull(String key) => _readOrNull<String>(key, 'String');

  bool boolean(String key) => _read<bool>(key, 'bool');

  int integer(String key) => _read<int>(key, 'int');

  JsonObject object(String key) =>
      JsonObject(_read<Map<String, dynamic>>(key, 'object'), '$_path.$key');

  JsonObject? objectOrNull(String key) {
    final value = _readOrNull<Map<String, dynamic>>(key, 'object');
    return value == null ? null : JsonObject(value, '$_path.$key');
  }

  /// A list of objects. A missing or null field is an empty list, which is
  /// what GraphQL connections and `userErrors` mean by absence.
  List<JsonObject> objects(String key) {
    final value = _map[key];
    if (value == null) return const [];
    if (value is! List) throw MalformedResponse('$_path.$key', 'list', value);
    return [
      for (final (index, item) in value.indexed)
        if (item is Map<String, dynamic>)
          JsonObject(item, '$_path.$key[$index]')
        else
          throw MalformedResponse('$_path.$key[$index]', 'object', item),
    ];
  }

  T _read<T>(String key, String expected) {
    final value = _map[key];
    if (value is T) return value;
    throw MalformedResponse('$_path.$key', expected, value);
  }

  T? _readOrNull<T>(String key, String expected) {
    final value = _map[key];
    if (value == null || value is T) return value as T?;
    throw MalformedResponse('$_path.$key', '$expected or null', value);
  }
}
