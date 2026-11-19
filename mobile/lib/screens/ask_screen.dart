import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../widgets.dart';

/// Ask a question (answer comes by email) + answered questions.
class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _body = TextEditingController();
  String _category = 'moving';
  bool _sending = false;
  bool _sent = false;
  Map<String, List<String>> _serverErrors = {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await Api.instance.askQuestion(
        name: _name.text.trim(),
        email: _email.text.trim(),
        category: _category,
        body: _body.text.trim(),
      );
      _body.clear();
      setState(() => _sent = true);
    } on ApiException catch (e) {
      setState(() => _serverErrors = e.fieldErrors);
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _err(String field) => _serverErrors[field]?.join(', ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask about Chennai')),
      body: Loader<List<Category>>(
        load: Api.instance.questionCategories,
        builder: (context, categories, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Rent, areas, autos, schools, weather, food, jobs, anything. We reply by email, and helpful '
              'answers may be shared below without your name or email.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (_sent) _sentCard() else _formCard(categories),
            const SizedBox(height: 28),
            Text('Answered questions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _AnswersList(categories: {for (final c in categories) c.key: c}),
          ],
        ),
      ),
    );
  }

  Widget _sentCard() => Card(
        color: const Color(0xFFECFDF5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Nandri! Your question has been sent.',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
            const SizedBox(height: 4),
            const Text('We will email you the answer. Need help faster? Use the Chat tab.'),
            const SizedBox(height: 8),
            TextButton(onPressed: () => setState(() => _sent = false), child: const Text('Ask another')),
          ]),
        ),
      );

  Widget _formCard(List<Category> categories) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: 'Your name', errorText: _err('name')),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Your email', errorText: _err('email')),
                validator: validateEmail,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Topic'),
                items: [
                  for (final c in categories) DropdownMenuItem(value: c.key, child: Text('${c.icon} ${c.label}')),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Your question',
                  hintText: 'e.g. Which area is good for a family working in OMR?',
                  alignLabelWithHint: true,
                  errorText: _err('body'),
                ),
                validator: (v) => (v ?? '').trim().length < 10 ? 'Please write at least 10 characters' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sending ? null : _submit,
                  child: Text(_sending ? 'Sending…' : 'Send question'),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// Shared by the Ask and Chat forms.
String? validateEmail(String? v) {
  final email = (v ?? '').trim();
  if (email.isEmpty) return 'Please enter your email';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) return 'Please enter a valid email';
  return null;
}

class _AnswersList extends StatelessWidget {
  const _AnswersList({required this.categories});

  final Map<String, Category> categories;

  @override
  Widget build(BuildContext context) {
    return Loader<List<Answer>>(
      load: Api.instance.answers,
      builder: (context, answers, _) {
        if (answers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Answers will appear here.', style: TextStyle(color: Colors.black54)),
          );
        }
        return Column(children: [
          for (final a in answers)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (categories[a.category] != null)
                      Text('${categories[a.category]!.icon} ${categories[a.category]!.label}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text('Q: ${a.question}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(a.answer),
                  ]),
                ),
              ),
            ),
        ]);
      },
    );
  }
}
