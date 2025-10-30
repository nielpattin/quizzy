import "dart:async";
import "package:supabase_flutter/supabase_flutter.dart";
import "api_service.dart";

class HomeRepository {
  HomeRepository._();
  static final HomeRepository instance = HomeRepository._();

  Map<String, dynamic>? _cache;
  DateTime? _updatedAt;
  Future<Map<String, dynamic>>? _inFlight;
  // Cache Time-To-Live
  Duration ttl = const Duration(seconds: 45);

  /// Returns last cached value if available and fresh
  Map<String, dynamic>? peek() => _isFresh ? _cache : null;

  bool get _isFresh {
    if (_cache == null || _updatedAt == null) return false;
    return DateTime.now().difference(_updatedAt!) < ttl;
  }

  /// Fetches data with cache + in-flight memoization
  Future<Map<String, dynamic>> get({bool force = false}) async {
    if (!force && _isFresh && _cache != null) {
      return _cache!;
    }
    if (_inFlight != null) {
      return _inFlight!;
    }
    _inFlight = _fetch().whenComplete(() {
      _inFlight = null;
    });
    final data = await _inFlight!;
    _cache = data;
    _updatedAt = DateTime.now();
    return data;
  }

  /// Starts a background refresh without awaiting it
  void prefetch() {
    // If fresh or already fetching, skip
    if (_isFresh || _inFlight != null) return;
    // ignore: discarded_futures
    unawaited(get());
  }

  Future<Map<String, dynamic>> _fetch() async {
    // Run network requests in parallel
    final results = await Future.wait([
      ApiService.getFeaturedQuizzes(),
      ApiService.getTrendingQuizzes(),
      ApiService.getCategories(),
    ]);

    final featured = results[0];
    final trending = results[1];
    final categories = results[2];

    final userId = Supabase.instance.client.auth.currentUser?.id;
    List<dynamic> continuePlaying = [];
    if (userId != null) {
      try {
        final playedSessions = await ApiService.getPlayedSessions(userId);
        continuePlaying = playedSessions
            .where((s) => s["endedAt"] == null)
            .toList();
      } catch (e) {
        // ignore network errors for continue playing
      }
    }

    return {
      'featured': featured,
      'trending': trending,
      'continuePlaying': continuePlaying,
      'categories': categories,
    };
  }
}
