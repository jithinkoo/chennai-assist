import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../widgets.dart';
import 'guide_screens.dart';
import 'interview_screens.dart';
import 'photos_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.openTab});

  /// Switches the bottom-navigation tab (see AppTab in main.dart).
  final void Function(int tab) openTab;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Hero(openTab: openTab),
            const SizedBox(height: 24),
            Text('Explore the city guide', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Loader<Map<String, Category>>(
              load: Api.instance.guideCategories,
              builder: (context, cats, _) => GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: [
                  for (final c in cats.values)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => GuideListScreen(initialCategory: c.key)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(children: [
                            Text(c.icon, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(c.label,
                                  maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Chennai in photos', onMore: () => openTab(3)),
            const SizedBox(height: 12),
            Loader<List<Photo>>(
              load: Api.instance.photos,
              builder: (context, photos, _) => photos.isEmpty
                  ? const Text('Photos are coming soon.', style: TextStyle(color: Colors.black54))
                  : SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length.clamp(0, 10),
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => SizedBox(width: 160, child: PhotoTile(photo: photos[i])),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Local voices',
              onMore: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InterviewsScreen())),
            ),
            const SizedBox(height: 12),
            Loader<List<InterviewSummary>>(
              load: Api.instance.interviews,
              builder: (context, items, _) => items.isEmpty
                  ? const Text('Interviews with local people are coming soon.', style: TextStyle(color: Colors.black54))
                  : Column(children: [
                      for (final i in items.take(3))
                        Padding(padding: const EdgeInsets.only(bottom: 10), child: InterviewCard(item: i)),
                    ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.openTab});

  final void Function(int tab) openTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Brand.sea, Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('VANAKKAM! WELCOME TO CHENNAI',
            style: TextStyle(color: Color(0xFFCCFBF1), letterSpacing: 1.5, fontSize: 12)),
        const SizedBox(height: 10),
        const Text(
          'Moving to, living in or visiting Chennai? Ask us anything.',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
        ),
        const SizedBox(height: 10),
        const Text(
          'Rent and areas, autos, weather, food, culture, people. A real person answers.',
          style: TextStyle(color: Color(0xFFF0FDFA)),
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
            onPressed: () => openTab(4),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Start a live chat'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            onPressed: () => openTab(2),
            child: const Text('Ask a question'),
          ),
        ]),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMore});

  final String title;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ),
      TextButton(onPressed: onMore, child: const Text('See all')),
    ]);
  }
}
