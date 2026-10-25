import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the session token the server gave this device, in secure storage.
///
/// A browser holds its session in an HTTP-only cookie that the app cannot
/// read, so there it keeps nothing.
class SessionStore {
  SessionStore({FlutterSecureStorage? storage, bool? web})
    : _storage = storage ?? const FlutterSecureStorage(),
      _web = web ?? kIsWeb;

  static const _key = 'session_token';

  final FlutterSecureStorage _storage;
  final bool _web;

  String? _token;
  bool _loaded = false;

  final _expired = StreamController<void>.broadcast();

  /// Fires when the server says the session is over.
  Stream<void> get onExpired => _expired.stream;

  Future<String?> token() async {
    if (_web) return null;
    if (!_loaded) {
      _token = await _storage.read(key: _key);
      _loaded = true;
    }
    return _token;
  }

  Future<void> save(String token) async {
    if (_web) return;
    _token = token;
    _loaded = true;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _token = null;
    _loaded = true;
    if (!_web) await _storage.delete(key: _key);
  }

  /// Called by the HTTP client when a request was refused as not signed in.
  void expire() => _expired.add(null);
}
