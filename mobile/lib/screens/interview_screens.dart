import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../widgets.dart';

class InterviewsScreen extends StatelessWidget {
  const InterviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local voices')),
      body: Loader<List<InterviewSummary>>(
        load: Api.instance.interviews,
        builder: (context, items, reload) => items.isEmpty
            ? const MessageView(icon: Icons.record_voice_over_outlined, text: 'Interviews are coming soon.')
            : RefreshIndicator(
                onRefresh: reload,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => InterviewCard(item: items[i]),
                ),
              ),
      ),
    );
  }
}

class InterviewCard extends StatelessWidget {
  const InterviewCard({super.key, required this.item});

  final InterviewSummary item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => InterviewDetailScreen(slug: item.slug, title: item.title)),
        ),
        child: Row(children: [
          if (item.photoUrl != null) SizedBox(width: 96, height: 96, child: NetImage(item.photoUrl!)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.area, style: t.labelMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 2),
                Text(item.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.personName, style: t.bodySmall),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class InterviewDetailScreen extends StatelessWidget {
  const InterviewDetailScreen({super.key, required this.slug, required this.title});

  final String slug;
  final String title;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: Loader<Interview>(
        load: () => Api.instance.interview(slug),
        builder: (context, i, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(i.title, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              [i.personName, if (i.occupation?.isNotEmpty ?? false) i.occupation, i.area].join(' · '),
              style: t.titleSmall?.copyWith(color: Colors.black54),
            ),
            if (i.photoUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(borderRadius: BorderRadius.circular(16), child: NetImage(i.photoUrl!, height: 240)),
            ],
            const SizedBox(height: 20),
            Prose(i.body),
          ],
        ),
      ),
    );
  }
}
