import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../config/app_config.dart';
import '../domain/json_object.dart';

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

enum StorefrontErrorKind {
  /// The request never got a usable answer (offline, timeout, DNS).
  network,

  /// The shop answered with an error message of its own (GraphQL errors or
  /// `userErrors`). The message is shown as the shop wrote it.
  server,
  emptyResponse,
  productNotFound,
  collectionNotFound,
}

/// A failure the user can be told about. The data layer only classifies;
/// wording is chosen in the UI through [describeError], so it is localized.
class StorefrontException implements Exception {
  const StorefrontException(this.kind, [this.serverMessage]);

  const StorefrontException.network() : this(StorefrontErrorKind.network);

  const StorefrontException.server(String message)
    : this(StorefrontErrorKind.server, message);

  factory StorefrontException.fromResult(QueryResult result) {
    final exception = result.exception;
    if (exception == null || exception.linkException != null) {
      return const StorefrontException.network();
    }
    return StorefrontException.server(
      exception.graphqlErrors.map((e) => e.message).join(', '),
    );
  }

  final StorefrontErrorKind kind;
  final String? serverMessage;

  @override
  String toString() =>
      'StorefrontException(${kind.name}'
      '${serverMessage == null ? '' : ': $serverMessage'})';
}

/// The response body of a successful request as a typed view. A request
/// that failed, or came back without data, becomes a [StorefrontException].
JsonObject dataOf(QueryResult result) {
  if (result.hasException) throw StorefrontException.fromResult(result);
  final data = result.data;
  if (data == null) {
    throw const StorefrontException(StorefrontErrorKind.emptyResponse);
  }
  return JsonObject(data);
}

/// What to show the user for any error that reached the UI. Only a
/// [StorefrontException] is translated into words for people; anything
/// else, including a malformed response, gets the generic line and is left
/// to the logs.
String describeError(AppLocalizations l10n, Object error) {
  if (error is! StorefrontException) return l10n.errorGeneric;
  return switch (error.kind) {
    StorefrontErrorKind.network => l10n.errorNetwork,
    StorefrontErrorKind.server => error.serverMessage ?? l10n.errorGeneric,
    StorefrontErrorKind.emptyResponse => l10n.errorEmptyResponse,
    StorefrontErrorKind.productNotFound => l10n.errorProductNotFound,
    StorefrontErrorKind.collectionNotFound => l10n.errorCollectionNotFound,
  };
}
