import 'package:flutter/material.dart';

import 'tabs/in_progress_tab.dart';
import 'tabs/main_tab.dart';

/// The post-login shell: a 5-tab bottom navigation. Tab 0 is the real screen;
/// tabs 1–4 are "in progress" placeholders.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = [
    'Home',
    'Discover',
    'Activity',
    'Messages',
    'Profile',
  ];

  static const _tabs = <Widget>[
    MainTab(),
    InProgressTab(title: 'Discover'),
    InProgressTab(title: 'Activity'),
    InProgressTab(title: 'Messages'),
    InProgressTab(title: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
