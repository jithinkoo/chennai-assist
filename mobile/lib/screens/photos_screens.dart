import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../widgets.dart';

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chennai in photos')),
      body: Loader<List<Photo>>(
        load: Api.instance.photos,
        builder: (context, photos, reload) => photos.isEmpty
            ? const MessageView(icon: Icons.photo_library_outlined, text: 'Photos are coming soon.')
            : RefreshIndicator(
                onRefresh: reload,
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, i) => PhotoTile(photo: photos[i]),
                ),
              ),
      ),
    );
  }
}

class PhotoTile extends StatelessWidget {
  const PhotoTile({super.key, required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PhotoViewer(photo: photo),
        )),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: NetImage(photo.imageUrl)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              photo.area == null || photo.area!.isEmpty ? photo.caption : '${photo.caption} · ${photo.area}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ]),
      ),
    );
  }
}

/// Full-screen photo with pinch-to-zoom.
class PhotoViewer extends StatelessWidget {
  const PhotoViewer({super.key, required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Column(children: [
        Expanded(
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(child: NetImage(photo.imageUrl, fit: BoxFit.contain)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            photo.area == null || photo.area!.isEmpty ? photo.caption : '${photo.caption} · ${photo.area}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ]),
    );
  }
}
