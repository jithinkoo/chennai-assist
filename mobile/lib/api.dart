import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// A failed API call, with a message that can be shown to the user.
class ApiException implements Exception {
  ApiException(this.message, {this.fieldErrors = const {}, this.status});

  final String message;
  final Map<String, List<String>> fieldErrors;
  final int? status;

  bool get notFound => status == 404;

  @override
  String toString() => message;
}

class Category {
  Category({required this.key, required this.label, required this.icon});

  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(key: j['key'], label: j['label'], icon: j['icon'] ?? '');

  final String key;
  final String label;
  final String icon;
}

class GuideSummary {
  GuideSummary({required this.slug, required this.title, required this.category, required this.summary});

  factory GuideSummary.fromJson(Map<String, dynamic> j) =>
      GuideSummary(slug: j['slug'], title: j['title'], category: j['category'], summary: j['summary'] ?? '');

  final String slug;
  final String title;
  final String category;
  final String summary;
}

class Guide extends GuideSummary {
  Guide({required super.slug, required super.title, required super.category, required super.summary, required this.body});

  factory Guide.fromJson(Map<String, dynamic> j) => Guide(
        slug: j['slug'],
        title: j['title'],
        category: j['category'],
        summary: j['summary'] ?? '',
        body: j['body'] ?? '',
      );

  final String body;
}

class Photo {
  Photo({required this.id, required this.caption, this.area, required this.imageUrl});

  factory Photo.fromJson(Map<String, dynamic> j) =>
      Photo(id: j['id'], caption: j['caption'] ?? '', area: j['area'], imageUrl: j['image_url']);

  final int id;
  final String caption;
  final String? area;
  final String imageUrl;
}

class InterviewSummary {
  InterviewSummary({
    required this.slug,
    required this.title,
    required this.personName,
    this.occupation,
    required this.area,
    this.photoUrl,
  });

  factory InterviewSummary.fromJson(Map<String, dynamic> j) => InterviewSummary(
        slug: j['slug'],
        title: j['title'],
        personName: j['person_name'] ?? '',
        occupation: j['occupation'],
        area: j['area'] ?? '',
        photoUrl: j['photo_url'],
      );

  final String slug;
  final String title;
  final String personName;
  final String? occupation;
  final String area;
  final String? photoUrl;
}

class Interview extends InterviewSummary {
  Interview({
    required super.slug,
    required super.title,
    required super.personName,
    super.occupation,
    required super.area,
    super.photoUrl,
    required this.body,
  });

  factory Interview.fromJson(Map<String, dynamic> j) => Interview(
        slug: j['slug'],
        title: j['title'],
        personName: j['person_name'] ?? '',
        occupation: j['occupation'],
        area: j['area'] ?? '',
        photoUrl: j['photo_url'],
        body: j['body'] ?? '',
      );

  final String body;
}

class Answer {
  Answer({required this.id, required this.category, required this.question, required this.answer});

  factory Answer.fromJson(Map<String, dynamic> j) =>
      Answer(id: j['id'], category: j['category'], question: j['question'], answer: j['answer'] ?? '');

  final int id;
  final String category;
  final String question;
  final String answer;
}

class ChatMessage {
  ChatMessage({required this.id, required this.sender, required this.body, required this.sentAt});

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        sender: j['sender'],
        body: j['body'],
        sentAt: DateTime.tryParse(j['sent_at'] ?? '')?.toLocal() ?? DateTime.now(),
      );

  final int id;
  final String sender; // "visitor" or "admin"
  final String body;
  final DateTime sentAt;

  bool get fromVisitor => sender == 'visitor';
}

class ChatSession {
  ChatSession({
    required this.token,
    required this.visitorName,
    required this.visitorEmail,
    required this.status,
    required this.messages,
  });

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        token: j['token'],
        visitorName: j['visitor_name'],
        visitorEmail: j['visitor_email'],
        status: j['status'] ?? 'open',
        messages: [for (final m in (j['messages'] as List? ?? [])) ChatMessage.fromJson(m)],
      );

  final String token;
  final String visitorName;
  final String visitorEmail;
  final String status;
  final List<ChatMessage> messages;
}

/// Client for the website's /api/v1 endpoints.
class Api {
  Api({http.Client? client, String? base})
      : _client = client ?? http.Client(),
        _base = base ?? apiBase;

  static final Api instance = Api();

  final http.Client _client;
  final String _base;

  // The free server may be asleep; waking it can take up to a minute.
  static const _timeout = Duration(seconds: 90);

  Future<Map<String, Category>> guideCategories() async {
    final j = await _get('/api/v1/categories');
    return {for (final c in j['guide']) c['key'] as String: Category.fromJson(c)};
  }

  Future<List<Category>> questionCategories() async {
    final j = await _get('/api/v1/categories');
    return [for (final c in j['question']) Category.fromJson(c)];
  }

  Future<List<GuideSummary>> guides({String? category}) async {
    final q = category == null ? '' : '?category=${Uri.encodeQueryComponent(category)}';
    final j = await _get('/api/v1/guides$q');
    return [for (final g in j['data']) GuideSummary.fromJson(g)];
  }

  Future<Guide> guide(String slug) async =>
      Guide.fromJson((await _get('/api/v1/guides/${Uri.encodeComponent(slug)}'))['data']);

  Future<List<Photo>> photos() async => [for (final p in (await _get('/api/v1/photos'))['data']) Photo.fromJson(p)];

  Future<List<InterviewSummary>> interviews() async =>
      [for (final i in (await _get('/api/v1/interviews'))['data']) InterviewSummary.fromJson(i)];

  Future<Interview> interview(String slug) async =>
      Interview.fromJson((await _get('/api/v1/interviews/${Uri.encodeComponent(slug)}'))['data']);

  Future<List<Answer>> answers({String? category}) async {
    final q = category == null ? '' : '?category=${Uri.encodeQueryComponent(category)}';
    return [for (final a in (await _get('/api/v1/answers$q'))['data']) Answer.fromJson(a)];
  }

  Future<void> askQuestion({
    required String name,
    required String email,
    required String category,
    required String body,
  }) async {
    await _post('/api/v1/questions', {'name': name, 'email': email, 'category': category, 'body': body});
  }

  Future<ChatSession> startChat({required String name, required String email, String? message}) async {
    final j = await _post('/api/v1/chats', {
      'visitor_name': name,
      'visitor_email': email,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
    });
    return ChatSession.fromJson(j['data']);
  }

  Future<ChatSession> chat(String token) async =>
      ChatSession.fromJson((await _get('/api/v1/chats/${Uri.encodeComponent(token)}'))['data']);

  Future<ChatMessage> sendMessage(String token, String body) async {
    final j = await _post('/api/v1/chats/${Uri.encodeComponent(token)}/messages', {'body': body});
    return ChatMessage.fromJson(j['data']);
  }

  // --- HTTP helpers -----------------------------------------------------------

  Future<dynamic> _get(String path) => _send(() => _client.get(Uri.parse('$_base$path'), headers: _headers));

  Future<dynamic> _post(String path, Map<String, dynamic> body) => _send(
        () => _client.post(Uri.parse('$_base$path'), headers: _headers, body: jsonEncode(body)),
      );

  static const _headers = {'accept': 'application/json', 'content-type': 'application/json'};

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Chennai Assist is taking too long to answer. Please try again.');
    } on http.ClientException {
      // Network failures (no internet, DNS, refused) arrive as ClientException.
      throw ApiException("Can't reach Chennai Assist. Check your internet connection and try again.");
    }

    final decoded = res.body.isEmpty ? null : _tryDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

    if (res.statusCode == 422 && decoded is Map && decoded['errors'] is Map) {
      final errors = <String, List<String>>{
        for (final e in (decoded['errors'] as Map).entries) e.key as String: [for (final m in e.value) '$m'],
      };
      throw ApiException('Please check the highlighted fields.', fieldErrors: errors, status: 422);
    }
    if (res.statusCode == 404) throw ApiException('Not found.', status: 404);
    throw ApiException('Something went wrong (error ${res.statusCode}). Please try again.', status: res.statusCode);
  }

  static dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}
