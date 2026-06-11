import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai/ai_cache.dart';
import '../services/ai/ai_client.dart';
import '../services/notification_service.dart';
import '../services/sync/ntfy_sync_service.dart';
import 'providers.dart';
import 'settings_controller.dart';

/// 在 main() 里用实际实例覆盖（见 Task 4 Step 4）。
final sharedPrefsProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError());

final settingsProvider = Provider<SettingsController>(
    (ref) => SettingsController(ref.watch(sharedPrefsProvider)));

/// AI 结果缓存：进程内长存（不随 aiClientProvider 重建而清空），省 token。
final aiCacheProvider = Provider<AiCache>((ref) => AiCache());

final aiClientProvider = Provider<AiClient>((ref) => AiClient(
      config: ref.watch(settingsProvider).aiConfig,
      cache: ref.watch(aiCacheProvider),
    ));

/// 在 main() 里用实际实例覆盖。
final notificationServiceProvider =
    Provider<NotificationService>((_) => throw UnimplementedError());

/// ntfy 单向同步服务（桌面→手机捕获落库）。App 运行期长存。
final ntfySyncServiceProvider = Provider<NtfySyncService>((ref) {
  final svc = NtfySyncService(db: ref.watch(databaseProvider));
  ref.onDispose(svc.stop);
  return svc;
});
