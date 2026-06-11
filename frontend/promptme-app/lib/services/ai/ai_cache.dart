/// AI 结果缓存：按 prompt 文本去重，命中即省一次网络请求 / token。
/// 进程内（内存）Map，由 keepAlive 的 aiCacheProvider 持有，
/// 跨 AiClient 重建（改设置会重建 client）仍存活。AI 关时根本不会走到这里。
class AiCache {
  final Map<String, String> _store = {};

  String? get(String prompt) => _store[prompt];
  void put(String prompt, String value) => _store[prompt] = value;

  bool has(String prompt) => _store.containsKey(prompt);
  void clear() => _store.clear();
  int get size => _store.length;
}
