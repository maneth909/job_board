import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/services/auth_service.dart';
import '../services/profile_service.dart';

class ProfileState {
  final bool isLoading;
  final String? role;
  final bool isCompleted;

  ProfileState({
    this.isLoading = true,
    this.role,
    this.isCompleted = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? role,
    bool? isCompleted,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      role: role ?? this.role,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final ProfileService _profileService;

  ProfileStateNotifier(this._profileService) : super(ProfileState());

  Future<void> fetchProfileStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final status = await _profileService.getProfileStatus();
      if (status != null) {
        state = ProfileState(
          isLoading: false,
          role: status['role'],
          isCompleted: status['isCompleted'],
        );
      } else {
        state = ProfileState(isLoading: false);
      }
    } catch (e) {
      state = ProfileState(isLoading: false);
    }
  }

  void markAsCompleted() {
    state = state.copyWith(isCompleted: true);
  }

  void reset() {
    state = ProfileState(isLoading: false);
  }
}

final profileStateProvider = StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  final notifier = ProfileStateNotifier(profileService);
  
  ref.listen(authStateProvider, (previous, next) {
    if (next.value?.session != null) {
      notifier.fetchProfileStatus();
    } else {
      notifier.reset();
    }
  });

  return notifier;
});
