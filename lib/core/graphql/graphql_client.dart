import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../config/app_config.dart';

final graphQLClientProvider = Provider<GraphQLClient>((ref) {
  final httpLink = HttpLink(
    AppConfig.storefrontEndpoint,
    defaultHeaders: {
      if (AppConfig.storefrontAccessToken.isNotEmpty)
        'X-Shopify-Storefront-Access-Token': AppConfig.storefrontAccessToken,
    },
  );

  return GraphQLClient(
    link: httpLink,
    cache: GraphQLCache(),
    // A stalled request must fail loudly, never spin forever.
    queryRequestTimeout: const Duration(seconds: 8),
    defaultPolicies: DefaultPolicies(
      query: Policies(fetch: FetchPolicy.cacheAndNetwork),
      mutate: Policies(fetch: FetchPolicy.networkOnly),
    ),
  );
});

class StorefrontException implements Exception {
  StorefrontException(this.message);

  factory StorefrontException.fromResult(QueryResult result) {
    final exception = result.exception;
    if (exception == null) return StorefrontException('Unknown error');
    if (exception.linkException != null) {
      return StorefrontException('Network error – please try again.');
    }
    return StorefrontException(
      exception.graphqlErrors.map((e) => e.message).join(', '),
    );
  }

  final String message;

  @override
  String toString() => message;
}
