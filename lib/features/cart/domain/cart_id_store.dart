/// Where the id of the customer's server-side cart is remembered between
/// app launches.
abstract interface class CartIdStore {
  Future<String?> read();
  Future<void> write(String id);
  Future<void> clear();
}
