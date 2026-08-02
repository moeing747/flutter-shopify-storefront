import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/graphql/graphql_client.dart';
import '../data/product_repository_graphql.dart';
import '../domain/product_detail.dart';
import '../domain/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => GraphQLProductRepository(ref.watch(graphQLClientProvider)),
);

// autoDispose so a failed or stalled fetch is not cached for the app's
// lifetime — leaving the page and coming back always refetches.
final productProvider = FutureProvider.autoDispose
    .family<ProductDetail, String>(
      (ref, id) => ref.watch(productRepositoryProvider).fetchProduct(id),
    );
