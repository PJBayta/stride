import 'package:flutter/foundation.dart';

import '../../../models/finished_session.dart';

/// Holds a finished activity until the user explicitly saves or discards it.
///
/// This state is deliberately in-memory only. It survives summary-sheet
/// dismissals during the current app session, but is never persisted unless
/// the user selects Save Activity.
class PendingActivityController extends ChangeNotifier {
  FinishedSession? _session;

  FinishedSession? get session => _session;

  bool get hasPendingActivity => _session != null;

  void hold(FinishedSession session) {
    _session = session;
    notifyListeners();
  }

  void clear() {
    if (_session == null) return;
    _session = null;
    notifyListeners();
  }
}

final PendingActivityController pendingActivityController =
    PendingActivityController();
