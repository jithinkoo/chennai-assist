import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../widgets.dart';

/// City guide: category chips + article list.
class GuideListScreen extends StatefulWidget {
  const GuideListScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<GuideListScreen> createState() => _GuideListScreenState();
}

class _GuideListScreenState extends State<GuideListScreen> {
  String? _category;
  Key _listKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  void _pick(String? category) => setState(() {
        _category = category;
        _listKey = UniqueKey();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('City guide')),
      body: Loader<Map<String, Category>>(
        load: Api.instance.guideCategories,
        builder: (context, categories, _) => Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _chip('All', null),
                  for (final c in categories.values) _chip('${c.icon} ${c.label}', c.key),
                ],
              ),
            ),
            Expanded(
              child: Loader<List<GuideSummary>>(
                key: _listKey,
                load: () => Api.instance.guides(category: _category),
                builder: (context, guides, reload) => guides.isEmpty
                    ? const MessageView(icon: Icons.menu_book_outlined, text: 'Nothing here yet. Ask us about it!')
                    : RefreshIndicator(
                        onRefresh: reload,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: guides.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => GuideCard(guide: guides[i], category: categories[guides[i].category]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? key) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: _category == key, onSelected: (_) => _pick(key)),
      );
}

class GuideCard extends StatelessWidget {
  const GuideCard({super.key, required this.guide, this.category});

  final GuideSummary guide;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GuideDetailScreen(slug: guide.slug, title: guide.title)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (category != null)
              Text('${category!.icon} ${category!.label}', style: t.labelMedium?.copyWith(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(guide.title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(guide.summary, style: t.bodyMedium?.copyWith(color: Colors.black54)),
          ]),
        ),
      ),
    );
  }
}

class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({super.key, required this.slug, required this.title});

  final String slug;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: Loader<Guide>(
        load: () => Api.instance.guide(slug),
        builder: (context, g, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(g.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(g.summary, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
            const SizedBox(height: 20),
            Prose(g.body),
            const SizedBox(height: 8),
            const HelpPrompt(),
          ],
        ),
      ),
    );
  }
}

/// "Still have a question?" box shown under articles.
class HelpPrompt extends StatelessWidget {
  const HelpPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Brand.sea.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Still have a question?', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Open the Chat tab to talk to a real person who knows Chennai.'),
      ]),
    );
  }
}
