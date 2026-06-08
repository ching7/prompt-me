import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai/ai_client.dart';
import '../services/notification_service.dart';
import 'settings_controller.dart';

/// 在 main() 里用实际实例覆盖（见 Task 4 Step 4）。
final sharedPrefsProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError());

final settingsProvider = Provider<SettingsController>(
    (ref) => SettingsController(ref.watch(sharedPrefsProvider)));

final aiClientProvider = Provider<AiClient>(
    (ref) => AiClient(config: ref.watch(settingsProvider).aiConfig));

/// 在 main() 里用实际实例覆盖。
final notificationServiceProvider =
    Provider<NotificationService>((_) => throw UnimplementedError());
