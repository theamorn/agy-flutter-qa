import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';

/// The first, fully-built tab. Greets the signed-in user and offers logout.
class MainTab extends StatelessWidget {
  const MainTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dashboard_customize_outlined,
              size: 72,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome${user != null ? ', ${user.name}' : ''}!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (user != null) ...[
              const SizedBox(height: 8),
              Text(user.email, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 24),
            const Text(
              'This is the main screen. The other four tabs are coming soon.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('logout_button'),
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
