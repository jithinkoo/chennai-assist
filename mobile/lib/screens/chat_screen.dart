import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import '../chat_channel.dart';
import '../widgets.dart';
import 'ask_screen.dart' show validateEmail;

const _tokenKey = 'chat_token';

/// Live chat with the Chennai Assist admin. The chat's secret token is kept on
/// the phone so the conversation is still there when the app is reopened.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  bool _loading = true;
  String? _error;
  ChatSession? _session;
  final List<ChatMessage> _messages = [];
  String _status = 'open';
  ChatChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _channel?.close();
    super.dispose();
  }

  // Coming back to the app: fetch anything missed while it was in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _session != null) _refresh();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      _open(await Api.instance.chat(token));
    } on ApiException catch (e) {
      if (e.notFound) {
        await prefs.remove(_tokenKey);
        setState(() => _loading = false);
      } else {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  void _open(ChatSession session) {
    _channel?.close();
    setState(() {
      _session = session;
      _status = session.status;
      _messages
        ..clear()
        ..addAll(session.messages);
      _loading = false;
      _error = null;
    });
    _channel = ChatChannel(
      token: session.token,
      onMessage: _add,
      onStatus: (s) => setState(() => _status = s),
      onReconnected: _refresh,
    )..connect();
  }

  Future<void> _refresh() async {
    final session = _session;
    if (session == null) return;
    try {
      final fresh = await Api.instance.chat(session.token);
      if (!mounted) return;
      setState(() => _status = fresh.status);
      fresh.messages.forEach(_add);
    } on ApiException {
      // Keep what we have; the next reconnect will try again.
    }
  }

  void _add(ChatMessage m) {
    if (!mounted || _messages.any((x) => x.id == m.id)) return;
    setState(() {
      _messages
        ..add(m)
        ..sort((a, b) => a.id.compareTo(b.id));
    });
  }

  Future<void> _started(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    _open(session);
  }

  Future<void> _newChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new chat?'),
        content: const Text('This conversation will be removed from this phone. '
            'You can still find it through the link we emailed you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('New chat')),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _channel?.close();
    _channel = null;
    setState(() {
      _session = null;
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live chat'),
        actions: [
          if (session != null)
            IconButton(tooltip: 'New chat', icon: const Icon(Icons.add_comment_outlined), onPressed: _newChat),
        ],
      ),
      body: _loading
          ? const MessageView()
          : _error != null
              ? MessageView(
                  icon: Icons.cloud_off,
                  text: _error,
                  action: FilledButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _restore();
                    },
                    child: const Text('Try again'),
                  ),
                )
              : session == null
                  ? _StartChatForm(onStarted: _started)
                  : _Conversation(session: session, messages: _messages, status: _status, onSent: _add),
    );
  }
}

class _StartChatForm extends StatefulWidget {
  const _StartChatForm({required this.onStarted});

  final Future<void> Function(ChatSession) onStarted;

  @override
  State<_StartChatForm> createState() => _StartChatFormState();
}

class _StartChatFormState extends State<_StartChatForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;
  Map<String, List<String>> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _errors = {});
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final session = await Api.instance.startChat(
        name: _name.text.trim(),
        email: _email.text.trim(),
        message: _message.text,
      );
      await widget.onStarted(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fieldErrors);
      showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Chat with a Chennai local',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text(
          'Your personal assistant for anything Chennai: travel, apartments, moving, weather, food, areas, '
          'culture. We reply here in real time, and by email if you have left.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: Column(children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: 'Your name', errorText: _errors['visitor_name']?.join(', ')),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Your email', errorText: _errors['visitor_email']?.join(', ')),
                  validator: validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _message,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'How can we help? (optional)',
                    hintText: "e.g. I'm joining a company in Guindy next month. Where should I stay?",
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _busy ? null : _start, child: Text(_busy ? 'Starting…' : 'Start chat')),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Conversation extends StatefulWidget {
  const _Conversation({required this.session, required this.messages, required this.status, required this.onSent});

  final ChatSession session;
  final List<ChatMessage> messages;
  final String status;
  final void Function(ChatMessage) onSent;

  @override
  State<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<_Conversation> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await Api.instance.sendMessage(widget.session.token, text);
      _input.clear();
      widget.onSent(msg);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgs = widget.messages;
    return Column(children: [
      if (widget.status == 'closed')
        Container(
          width: double.infinity,
          color: Colors.black12,
          padding: const EdgeInsets.all(8),
          child: const Text('This chat was closed. Send a message to reopen it.', textAlign: TextAlign.center),
        ),
      Expanded(
        child: ListView.builder(
          reverse: true, // newest at the bottom, list starts scrolled down
          padding: const EdgeInsets.all(12),
          itemCount: msgs.length + 1,
          itemBuilder: (context, i) {
            if (i == msgs.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Hi ${widget.session.visitorName}! Ask anything about Chennai. '
                  'Your chat link was also emailed to ${widget.session.visitorEmail}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              );
            }
            return _Bubble(message: msgs[msgs.length - 1 - i]);
          },
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type your message…',
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromVisitor;
    final time = TimeOfDay.fromDateTime(message.sentAt).format(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? Brand.orange : Brand.sea.withValues(alpha: 0.10),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!mine)
            const Text('Chennai Assist',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Brand.sea)),
          Text(message.body, style: TextStyle(color: mine ? Colors.white : Colors.black87, fontSize: 15)),
          const SizedBox(height: 2),
          Text(time, style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.black45)),
        ]),
      ),
    );
  }
}
