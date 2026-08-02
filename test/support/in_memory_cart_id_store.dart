import 'package:basics_storefront/features/cart/domain/cart_id_store.dart';

class InMemoryCartIdStore implements CartIdStore {
  InMemoryCartIdStore([this.id]);

  String? id;

  @override
  Future<String?> read() async => id;

  @override
  Future<void> write(String value) async => id = value;

  @override
  Future<void> clear() async => id = null;
}
