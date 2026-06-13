import 'package:equatable/equatable.dart';

/// A signed-in user of the app. Intentionally tiny — just enough to render
/// the main tab and prove a session exists.
class AppUser extends Equatable {
  const AppUser({required this.email, required this.name});

  final String email;
  final String name;

  @override
  List<Object?> get props => [email, name];
}
