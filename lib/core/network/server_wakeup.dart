import 'package:flutter/foundation.dart';

/// Whether the app is currently waiting on a request that has run long enough
/// to look like a stall.
///
/// The API is deployed on Render's free tier, which spins the service down
/// when it goes idle. The first request after a quiet period then waits on a
/// cold start that can run close to a minute — long enough that a silent
/// spinner reads as a hang. `SlowRequestInterceptor` flips this on once a
/// request passes `ApiConfig.slowRequestThreshold` and off again when it
/// finishes; `ServerWakeupBanner` renders the explanation.
///
/// Requests are tracked by identity rather than counted, so the same request
/// finishing twice — or finishing without ever having been marked slow —
/// cannot leave the banner stuck on screen.
class ServerWakeupNotifier extends ChangeNotifier
    implements ValueListenable<bool> {
  /// The one every `SlowRequestInterceptor` and the banner share. A plain
  /// static instance, like `ProfileStore.instance`: the banner sits above the
  /// router, outside the reach of any BLoC provider.
  static final instance = ServerWakeupNotifier();

  final _slowRequests = <Object>{};

  /// True while at least one request has been slow for long enough to explain.
  @override
  bool get value => _slowRequests.isNotEmpty;

  /// Marks [request] as slow. Idempotent.
  void markSlow(Object request) {
    if (_slowRequests.add(request) && _slowRequests.length == 1) {
      notifyListeners();
    }
  }

  /// Marks [request] as finished, however it finished. Safe to call for a
  /// request that was never slow.
  void markFinished(Object request) {
    if (_slowRequests.remove(request) && _slowRequests.isEmpty) {
      notifyListeners();
    }
  }

  @visibleForTesting
  void reset() {
    if (_slowRequests.isEmpty) return;
    _slowRequests.clear();
    notifyListeners();
  }
}
