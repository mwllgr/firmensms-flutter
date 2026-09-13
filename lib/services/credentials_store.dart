import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef Credentials = ({String username, String password});

class CredentialsStore {
  const CredentialsStore([this._storage = const FlutterSecureStorage()]);

  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';

  final FlutterSecureStorage _storage;

  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  Future<void> writeUsername(String username) =>
      _storage.write(key: _usernameKey, value: username);

  Future<void> writePassword(String password) =>
      _storage.write(key: _passwordKey, value: password);

  Future<Credentials?> read() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    if (username == null || password == null) {
      return null;
    }
    return (username: username, password: password);
  }
}
