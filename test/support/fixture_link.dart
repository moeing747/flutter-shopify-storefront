import 'dart:convert';
import 'dart:io';

import 'package:graphql_flutter/graphql_flutter.dart';

/// Replays responses recorded verbatim from mock.shop (test/fixtures/).
/// Fixtures must include `__typename` at every level — graphql_flutter
/// injects it into all outgoing documents and cache normalization fails
/// without it in the response.
class FixtureLink extends Link {
  FixtureLink(this._payloads);

  FixtureLink.fromFiles(List<String> fixtureNames)
    : this(fixtureNames.map(loadFixture).toList());

  final List<Map<String, dynamic>> _payloads;

  final List<Request> requests = [];

  static Map<String, dynamic> loadFixture(String name) =>
      json.decode(File('test/fixtures/$name').readAsStringSync())
          as Map<String, dynamic>;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    requests.add(request);
    final payload = _payloads[(requests.length - 1) % _payloads.length];
    return Stream.value(
      Response(
        data: payload['data'] as Map<String, dynamic>?,
        errors: (payload['errors'] as List?)
            ?.map((e) => GraphQLError(message: (e as Map)['message'] as String))
            .toList(),
        response: payload,
      ),
    );
  }
}

GraphQLClient clientWith(Link link) =>
    GraphQLClient(link: link, cache: GraphQLCache());
