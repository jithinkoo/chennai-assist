import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'api.dart';

/// Brand colours, matching the website.
class Brand {
  static const orange = Color(0xFFC2410C);
  static const sea = Color(0xFF0E5E6F);
  static const sand = Color(0xFFFBF6EE);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.orange,
    primary: Brand.orange,
    secondary: Brand.sea,
    surface: Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Brand.sand,
    appBarTheme: const AppBarTheme(backgroundColor: Brand.sand, centerTitle: false, scrolledUnderElevation: 0),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Loads [load] and shows a spinner, an error with Retry, or [builder].
/// After a few seconds of loading it explains that the server may be waking up.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  late Future<T> _future;
  bool _slow = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _slow = false;
    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _slow = true);
    });
    _future = widget.load().whenComplete(() => _slowTimer?.cancel());
  }

  Future<void> _reload() async {
    setState(_start);
    try {
      await _future;
    } catch (_) {}
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) return widget.builder(context, snap.data as T, _reload);
        if (snap.hasError) {
          return MessageView(
            icon: Icons.cloud_off,
            text: snap.error is ApiException ? '${snap.error}' : 'Something went wrong.',
            action: FilledButton(onPressed: _reload, child: const Text('Try again')),
          );
        }
        return MessageView(
          icon: null,
          text: _slow ? 'Waking up Chennai Assist… this can take up to a minute the first time.' : null,
        );
      },
    );
  }
}

/// Centered spinner/icon with an optional message and action.
class MessageView extends StatelessWidget {
  const MessageView({super.key, this.icon, this.text, this.action});

  final IconData? icon;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == null) const CircularProgressIndicator() else Icon(icon, size: 48, color: Colors.black38),
            if (text != null) ...[
              const SizedBox(height: 16),
              Text(text!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Network image with a soft placeholder and a broken-image fallback.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.height});

  final String url;
  final BoxFit fit;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      height: height,
      width: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Container(height: height, color: Colors.black12),
      errorBuilder: (context, _, _) => Container(
        height: height ?? 160,
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.black38),
      ),
    );
  }
}

/// Renders the admin's plain-text articles like the website does:
/// blank line = new paragraph, "- " lines = bullets, a short line without a
/// full stop followed by text = sub-heading.
class Prose extends StatelessWidget {
  const Prose(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).textTheme;
    final body = styles.bodyLarge?.copyWith(height: 1.5, color: Colors.black87);
    final children = <Widget>[];

    for (final block in parseProse(text)) {
      switch (block) {
        case ProseHeading(:final text, :final rest):
          children.add(Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(text, style: styles.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ));
          if (rest.isNotEmpty) children.add(Text(rest, style: body));
        case ProseList(:final items):
          for (final item in items) {
            children.add(Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('•  ', style: body),
                Expanded(child: Text(item, style: body)),
              ]),
            ));
          }
        case ProsePara(:final text):
          children.add(Text(text, style: body));
      }
      children.add(const SizedBox(height: 12));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

sealed class ProseBlock {}

class ProseHeading extends ProseBlock {
  ProseHeading(this.text, this.rest);
  final String text;
  final String rest;
}

class ProseList extends ProseBlock {
  ProseList(this.items);
  final List<String> items;
}

class ProsePara extends ProseBlock {
  ProsePara(this.text);
  final String text;
}

List<ProseBlock> parseProse(String text) {
  bool isItem(String l) => l.startsWith('- ');
  bool isHeading(String l) => l.length <= 60 && !RegExp(r'[.:?!]$').hasMatch(l);

  final blocks = <ProseBlock>[];
  for (final chunk in text.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'))) {
    final lines = [for (final l in chunk.split('\n')) l.trim()].where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) continue;
    final multi = lines.length > 1;

    // Group consecutive bullet / non-bullet lines.
    final groups = <List<String>>[];
    for (final line in lines) {
      if (groups.isNotEmpty && isItem(groups.last.first) == isItem(line)) {
        groups.last.add(line);
      } else {
        groups.add([line]);
      }
    }
    for (final g in groups) {
      if (isItem(g.first)) {
        blocks.add(ProseList([for (final l in g) l.substring(2)]));
      } else if (multi && isHeading(g.first)) {
        blocks.add(ProseHeading(g.first, g.skip(1).join(' ')));
      } else {
        blocks.add(ProsePara(g.join(' ')));
      }
    }
  }
  return blocks;
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
