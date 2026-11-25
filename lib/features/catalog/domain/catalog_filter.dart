enum CatalogSort {
  /// The shop's own order (manual or best-selling, as configured).
  shopDefault,
  priceLowToHigh,
  priceHighToLow,
}

/// What the catalog page is currently showing: one collection or all
/// products, in one sort order. Immutable; the controller swaps instances.
class CatalogFilter {
  const CatalogFilter({
    this.collectionHandle,
    this.sort = CatalogSort.shopDefault,
  });

  static const all = CatalogFilter();

  /// Null means every product in the shop.
  final String? collectionHandle;
  final CatalogSort sort;

  CatalogFilter copyWith({
    String? Function()? collectionHandle,
    CatalogSort? sort,
  }) => CatalogFilter(
    collectionHandle: collectionHandle == null
        ? this.collectionHandle
        : collectionHandle(),
    sort: sort ?? this.sort,
  );

  @override
  bool operator ==(Object other) =>
      other is CatalogFilter &&
      other.collectionHandle == collectionHandle &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(collectionHandle, sort);
}
