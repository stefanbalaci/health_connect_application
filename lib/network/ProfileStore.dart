import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide reactive cache of the signed-in user's display name + avatar.
///
/// Tabs live in an [IndexedStack] (kept alive), so editing the profile in one
/// tab wouldn't otherwise refresh another. Screens listen to these notifiers so
/// a profile change reflects everywhere instantly. Values are also mirrored to
/// SharedPreferences (`user_name`, `user_avatar`) for fast startup.
class ProfileStore {
  ProfileStore._();

  static final ValueNotifier<String> name = ValueNotifier<String>('');
  static final ValueNotifier<int?> avatarId = ValueNotifier<int?>(null);

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    name.value = prefs.getString('user_name') ?? '';
    avatarId.value = prefs.getInt('user_avatar');
  }

  static Future<void> setName(String value) async {
    name.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', value);
  }

  static Future<void> setAvatar(int? id) async {
    avatarId.value = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setInt('user_avatar', id);
    } else {
      await prefs.remove('user_avatar');
    }
  }

  static void clear() {
    name.value = '';
    avatarId.value = null;
  }
}
