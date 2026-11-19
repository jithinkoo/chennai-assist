import 'dart:convert';

import 'package:chennai_assist/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Api apiWith(Future<http.Response> Function(http.Request) handler) =>
      Api(client: MockClient(handler), base: 'https://example.test');

  http.Response jsonResponse(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  test('guides are parsed and the category filter is sent', () async {
    late Uri requested;
    final api = apiWith((req) async {
      requested = req.url;
      return jsonResponse({
        'data': [
          {'slug': 'autos', 'title': 'Autos', 'category': 'transport', 'summary': 'Use apps'},
        ],
      });
    });

    final guides = await api.guides(category: 'transport');
    expect(requested.toString(), 'https://example.test/api/v1/guides?category=transport');
    expect(guides.single.title, 'Autos');
  });

  test('starting a chat sends the visitor details and returns the session', () async {
    late Map<String, dynamic> sent;
    final api = apiWith((req) async {
      sent = jsonDecode(req.body);
      return jsonResponse({
        'data': {
          'token': 'abc',
          'visitor_name': 'Ravi',
          'visitor_email': 'r@example.com',
          'status': 'open',
          'messages': [
            {'id': 1, 'sender': 'visitor', 'body': 'Hi', 'sent_at': '2026-11-19T10:00:00Z'},
          ],
        },
      }, 201);
    });

    final session = await api.startChat(name: 'Ravi', email: 'r@example.com', message: '  Hi  ');
    expect(sent, {'visitor_name': 'Ravi', 'visitor_email': 'r@example.com', 'message': 'Hi'});
    expect(session.token, 'abc');
    expect(session.messages.single.fromVisitor, isTrue);
  });

  test('an empty optional message is not sent', () async {
    late Map<String, dynamic> sent;
    final api = apiWith((req) async {
      sent = jsonDecode(req.body);
      return jsonResponse({
        'data': {'token': 't', 'visitor_name': 'A', 'visitor_email': 'a@b.co', 'status': 'open', 'messages': []},
      }, 201);
    });
    await api.startChat(name: 'A', email: 'a@b.co', message: '   ');
    expect(sent.containsKey('message'), isFalse);
  });

  test('422 validation errors become field errors', () async {
    final api = apiWith((_) async => jsonResponse({
          'errors': {
            'email': ['enter a valid email'],
          },
        }, 422));

    expect(
      () => api.askQuestion(name: 'A', email: 'x', category: 'food', body: 'Long enough question'),
      throwsA(isA<ApiException>()
          .having((e) => e.fieldErrors['email'], 'email errors', ['enter a valid email'])
          .having((e) => e.status, 'status', 422)),
    );
  });

  test('404 is reported as notFound', () async {
    final api = apiWith((_) async => jsonResponse({'error': 'not_found'}, 404));
    expect(() => api.chat('gone'), throwsA(isA<ApiException>().having((e) => e.notFound, 'notFound', isTrue)));
  });

  test('network failures give a friendly message', () async {
    final api = apiWith((_) async => throw http.ClientException('Connection refused'));
    expect(
      () => api.photos(),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains("Can't reach Chennai Assist"))),
    );
  });
}
