/// A Shopify collection, used as the catalog's category filter.
class Collection {
  const Collection({
    required this.id,
    required this.handle,
    required this.title,
  });

  final String id;
  final String handle;
  final String title;
}
