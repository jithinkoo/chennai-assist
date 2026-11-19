import 'package:material_ui/material_ui.dart';

import 'screens/ask_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/guide_screens.dart';
import 'screens/home_screen.dart';
import 'screens/photos_screens.dart';
import 'widgets.dart';

void main() => runApp(const ChennaiAssistApp());

class ChennaiAssistApp extends StatelessWidget {
  const ChennaiAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chennai Assist',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AppShell(),
    );
  }
}

/// Bottom tabs: 0 Home, 1 Guide, 2 Ask, 3 Photos, 4 Chat.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  // Tabs are built once and kept alive, so a live chat keeps its connection
  // while the visitor browses other tabs.
  late final List<Widget> _pages = [
    HomeScreen(openTab: _open),
    const GuideListScreen(),
    const AskScreen(),
    const PhotosScreen(),
    const ChatScreen(),
  ];

  void _open(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _open,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Guide'),
          NavigationDestination(icon: Icon(Icons.help_outline), selectedIcon: Icon(Icons.help), label: 'Ask'),
          NavigationDestination(icon: Icon(Icons.photo_outlined), selectedIcon: Icon(Icons.photo), label: 'Photos'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
        ],
      ),
    );
  }
}
