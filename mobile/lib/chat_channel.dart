import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';
import 'config.dart';

/// Live updates for one chat over the website's Phoenix channel
/// ("chat:TOKEN" on /socket), using the Phoenix v2 JSON wire format:
/// `[join_ref, ref, topic, event, payload]`.
///
/// Reconnects automatically; [onReconnected] lets the screen re-fetch any
/// messages missed while the connection was down.
class ChatChannel {
  ChatChannel({
    required this.token,
    required this.onMessage,
    required this.onStatus,
    this.onReconnected,
    String? base,
  }) : _base = base ?? apiBase;

  final String token;
  final void Function(ChatMessage message) onMessage;
  final void Function(String status) onStatus;
  final void Function()? onReconnected;
  final String _base;

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _sub;
  Timer? _heartbeat;
  Timer? _retry;
  int _ref = 0;
  String? _joinRef;
  bool _closed = false;
  bool _everJoined = false;
  int _attempt = 0;

  String get _topic => 'chat:$token';

  Uri get socketUri {
    final ws = _base.replaceFirst(RegExp(r'^http'), 'ws');
    return Uri.parse('$ws/socket/websocket?vsn=2.0.0');
  }

  void connect() {
    if (_closed) return;
    try {
      _ws = WebSocketChannel.connect(socketUri);
    } catch (_) {
      _scheduleRetry();
      return;
    }
    _sub = _ws!.stream.listen(_onData, onDone: _onDown, onError: (_) => _onDown(), cancelOnError: true);
    _joinRef = _nextRef();
    _push(_joinRef, _joinRef!, _topic, 'phx_join', const {});
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      _push(null, _nextRef(), 'phoenix', 'heartbeat', const {});
    });
  }

  void close() {
    _closed = true;
    _retry?.cancel();
    _heartbeat?.cancel();
    _sub?.cancel();
    _ws?.sink.close();
  }

  void _onData(dynamic raw) {
    final List<dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as List<dynamic>;
    } catch (_) {
      return;
    }
    final ref = msg[1];
    final event = msg[3] as String;
    final payload = msg[4];

    switch (event) {
      case 'phx_reply' when ref == _joinRef:
        if (payload is Map && payload['status'] == 'ok') {
          if (_everJoined) onReconnected?.call();
          _everJoined = true;
          _attempt = 0;
        }
      case 'new_message' when payload is Map<String, dynamic>:
        onMessage(ChatMessage.fromJson(payload));
      case 'status' when payload is Map:
        onStatus('${payload['status']}');
      case 'phx_error' || 'phx_close':
        _onDown();
    }
  }

  void _onDown() {
    _heartbeat?.cancel();
    _sub?.cancel();
    _sub = null;
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_closed || (_retry?.isActive ?? false)) return;
    _attempt += 1;
    final seconds = [1, 2, 5, 10, 15, 30][(_attempt - 1).clamp(0, 5)];
    _retry = Timer(Duration(seconds: seconds), connect);
  }

  String _nextRef() => '${++_ref}';

  void _push(String? joinRef, String ref, String topic, String event, Map<String, dynamic> payload) {
    try {
      _ws?.sink.add(jsonEncode([joinRef, ref, topic, event, payload]));
    } catch (_) {
      // Connection is down; the retry timer will reconnect.
    }
  }
}
