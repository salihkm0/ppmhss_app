import 'package:dio/dio.dart';
import 'package:school_management/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management/services/socket_service.dart';
import 'package:redux/redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/actions/auth_actions.dart';
import 'package:school_management/main.dart'; // Add for navigatorKey

// ── Lightweight in-memory TTL cache ──────────────────────────────────
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;
  _CacheEntry(this.data, Duration ttl) : expiry = DateTime.now().add(ttl);
  bool get isExpired => DateTime.now().isAfter(expiry);
}

class _ApiCache {
  final Map<String, _CacheEntry> _store = {};

  dynamic get(String key) {
    final entry = _store[key];
    if (entry == null || entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.data;
  }

  void set(String key, dynamic value, {Duration ttl = const Duration(minutes: 5)}) {
    _store[key] = _CacheEntry(value, ttl);
  }

  void invalidate(String keyPrefix) {
    _store.removeWhere((k, _) => k.startsWith(keyPrefix));
  }

  void clear() => _store.clear();
}
// ─────────────────────────────────────────────────────────────────────

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  SharedPreferences? _prefs;
  final SocketService _socketService = SocketService();
  Store<AppState>? _store;

  // Shared cache instance
  final _ApiCache _cache = _ApiCache();

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _prefs?.getString('token');
        print('🌐 API Request: ${options.method} ${options.uri}');
        print('🌐 Token available in prefs: ${token != null}');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _prefs?.remove('token');
          await _prefs?.remove('refreshToken');
          _socketService.disconnect();
          _store?.dispatch(LogoutSuccessAction());
        } else if (error.response?.statusCode == 503) {
          // Maintenance Mode
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/maintenance', (route) => false);
        }
        return handler.next(error);
      },
    ));
  }

  /// GET with optional TTL cache.
  /// [noCache] bypasses cache for this call (e.g. after mutations).
  /// [cacheTtl] overrides the default 5-minute TTL.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? params,
    bool noCache = false,
    Duration cacheTtl = const Duration(minutes: 5),
  }) async {
    final cacheKey = '$path?${params?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? ''}';

    if (!noCache) {
      final cached = _cache.get(cacheKey);
      if (cached != null) return cached as Response;
    }

    final response = await _dio.get(path, queryParameters: params);
    if (!noCache) _cache.set(cacheKey, response, ttl: cacheTtl);
    return response;
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await _dio.delete(path, data: data);
  }

  String getToken() => _prefs?.getString('token') ?? '';

  SocketService get socketService => _socketService;

  void setStore(Store<AppState> store) {
    _store = store;
  }

  /// Invalidate cached responses whose key starts with [prefix].
  /// Call after mutations: e.g. invalidateCache('/attendance') after saving.
  void invalidateCache(String prefix) => _cache.invalidate(prefix);

  /// Clear entire cache (e.g. on logout).
  void clearCache() => _cache.clear();
}