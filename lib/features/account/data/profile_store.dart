import 'package:flutter/foundation.dart';

/// The signed-in user's account details.
class Profile {
  const Profile({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.location,
    required this.joined,
    this.hue = 262,
  });

  final String name;
  final String email;
  final String phone;

  /// Job title shown under the name ("Finance Manager").
  final String role;
  final String location;

  /// Human-readable join date ("March 2023").
  final String joined;

  /// Category hue for the avatar tint.
  final double hue;

  Profile copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? location,
    String? joined,
    double? hue,
  }) => Profile(
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    location: location ?? this.location,
    joined: joined ?? this.joined,
    hue: hue ?? this.hue,
  );
}

/// In-memory store of the current [Profile], shared across account screens.
///
/// Front-end only (mirrors `BudgetStore`): holds a seeded profile and notifies
/// listeners when the Edit-profile form saves. Not persisted — feed it from a
/// real auth/repository layer to survive restarts.
class ProfileStore {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  final ValueNotifier<Profile> profile = ValueNotifier(_seed);

  /// The current profile value (without listening).
  Profile get current => profile.value;

  /// Replaces the current profile (called by the Edit-profile form).
  set current(Profile next) => profile.value = next;

  static const _seed = Profile(
    name: 'Amara Mensah',
    email: 'amara.mensah@northpeak.co',
    phone: '+1 (415) 555-0138',
    role: 'Finance Manager',
    location: 'San Francisco, CA',
    joined: 'March 2023',
  );
}
