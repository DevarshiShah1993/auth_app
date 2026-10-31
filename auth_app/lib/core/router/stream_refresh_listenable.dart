import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a [Stream] to a [Listenable] for `GoRouter.refreshListenable`.
/// Call [dispose] to cancel the subscription.
class StreamRefreshListenable extends ChangeNotifier {
  /// Notifies listeners on every event of [stream].
  StreamRefreshListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
