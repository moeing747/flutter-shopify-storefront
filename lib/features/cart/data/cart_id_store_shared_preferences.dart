import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cart_id_store.dart';

class SharedPreferencesCartIdStore implements CartIdStore {
  static const _key = 'cart_id';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String id) async =>
      (await SharedPreferences.getInstance()).setString(_key, id);

  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
