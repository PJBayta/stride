import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/user_profile.dart';

class ProfileController extends ChangeNotifier {
  static const _hasCompletedOnboardingKey = 'hasCompletedOnboarding';
  static const _nameKey = 'profile_name';
  static const _weightKey = 'profile_weight_kg';
  static const _heightKey = 'profile_height_cm';
  static const _genderKey = 'profile_gender';

  SharedPreferences? _preferences;
  bool hasCompletedOnboarding = false;
  UserProfile profile = const UserProfile(name: '', weightKg: 70);

  double get strideLengthMeters => profile.strideLengthMeters;

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    final preferences = _preferences!;
    hasCompletedOnboarding =
        preferences.getBool(_hasCompletedOnboardingKey) ?? false;
    profile = UserProfile(
      name: preferences.getString(_nameKey) ?? '',
      weightKg: preferences.getDouble(_weightKey) ?? 70,
      heightCm: preferences.getDouble(_heightKey),
      gender: preferences.getString(_genderKey),
    );
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile updatedProfile) async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    profile = updatedProfile;
    notifyListeners();

    await preferences.setString(_nameKey, updatedProfile.name);
    await preferences.setDouble(_weightKey, updatedProfile.weightKg);
    if (updatedProfile.heightCm == null) {
      await preferences.remove(_heightKey);
    } else {
      await preferences.setDouble(_heightKey, updatedProfile.heightCm!);
    }
    if (updatedProfile.gender == null || updatedProfile.gender!.isEmpty) {
      await preferences.remove(_genderKey);
    } else {
      await preferences.setString(_genderKey, updatedProfile.gender!);
    }
  }

  Future<void> completeOnboarding(UserProfile updatedProfile) async {
    await saveProfile(updatedProfile);
    hasCompletedOnboarding = true;
    notifyListeners();
    await (_preferences ??= await SharedPreferences.getInstance()).setBool(
      _hasCompletedOnboardingKey,
      true,
    );
  }
}

final ProfileController profileController = ProfileController();
